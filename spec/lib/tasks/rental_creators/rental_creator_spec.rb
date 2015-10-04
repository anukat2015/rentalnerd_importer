require 'spec_helper'
require './lib/tasks/rental_creators/rental_creator'

class Includer
  include RentalCreator
end

RSpec.describe RentalCreator do

  let(:ic) { Includer.new }
  let(:pp) { create(:property) }
  let(:ij) { create(:import_job) }  
  let(:listed_date) { 1.year.ago }
  let(:closed_date) { Time.now }
  let(:default_time) { Time.now }
  let(:transacted_date) { Time.now }

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  def csv_headers
    headers = ["address", "neighborhood", "bedrooms", "bathrooms", "price", "sqft", "source", "origin_url", "import_job_id", "transaction_type", "date_closed", "date_listed"]    
  end

  def default_attributes
    default_attrs = {
      "address" => "111 some address", 
      "neighborhood" => "some neighborhood", 
      "bedrooms" => "5", 
      "bathrooms" => "5", 
      "price" => "100", 
      "sqft" => "50", 
      "source" => "lalaland", 
      "origin_url" => "http://google.com", 
      "import_job_id" => "1",
      "transaction_type" => "rental", 
      "date_closed" => nil, 
      "date_listed" => nil
    }.with_indifferent_access
  end

  def generate_row attrs
    combined_attrs = attrs.reverse_merge default_attributes
    row_array = csv_headers.map { |key| combined_attrs[key] }
    row = CSV::Row.new(csv_headers, row_array)
  end

  before do
    ic.stub(:get_default_date_listed) { default_time }
    google_map_request
  end

  describe '#create_import_log' do
    it 'creates a new import_log and sets date_transacted with date_listed if only date_listed is provided' do
      listed_date.strftime("%m/%d/%y")
      row = generate_row date_listed: listed_date.strftime("%m/%d/%Y")
      ic.create_import_log row
      il = ImportLog.all.first
      il.date_listed.should == listed_date.to_date
      il.date_transacted.should == listed_date.to_date
      il.date_closed.nil?.should == true
    end

    it 'creates a new import_log and sets date_transacted with date_closed if only date_closed is provided' do
      listed_date.strftime("%m/%d/%y")
      row = generate_row date_closed: closed_date.strftime("%m/%d/%Y")
      ic.create_import_log row
      il = ImportLog.all.first
      il.date_closed.should == closed_date.to_date
      il.date_transacted.should == closed_date.to_date
      il.date_listed.nil?.should == true
    end

    it 'creates a new import_log and sets date_transacted with date_closed if both date_closed and date_listed are provided' do
      listed_date.strftime("%m/%d/%y")
      row = generate_row date_closed: closed_date.strftime("%m/%d/%Y"), date_listed: listed_date.strftime("%m/%d/%Y")
      ic.create_import_log row
      il = ImportLog.all.first
      il.date_closed.should == closed_date.to_date
      il.date_transacted.should == closed_date.to_date
      il.date_listed.nil?.should == false
    end
  end

  describe '#create_transaction' do
    it 'sets date_listed as current time if both date listed and date closed are not available ' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood)
      ic.create_transaction imd
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.should == default_time.to_date
    end

    it 'does not set date_listed if date list is not available and date closed is available' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.nil?.should == true
      curr_ptl.date_closed.should == default_time.to_date
    end

    it 'does not set date_listed if date list is not available and date closed was already recorded in an existing transaction log' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd2
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.nil?.should == true
      curr_ptl.date_closed.should == default_time.to_date
    end

    it 'creates a new transaction log if date_listed is after the date_closed' do
      default_time = 1.year.ago
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: Time.now)
      ic.create_transaction imd2
      pp.property_transaction_logs.size.should == 2
    end

    it 'appends date_listed to an existing transaction log if date_listed is before the date_closed' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: closed_date)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date)
      ic.create_transaction imd2
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.should == list_date.to_date
      curr_ptl.date_closed.should == closed_date.to_date
    end

    it 'ignores transactions with the exact closed_date' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: closed_date)
      ic.create_transaction imd
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
    end

    it 'ignores transactions with the exact listed_date' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date)
      ic.create_transaction imd
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
    end

    it 'does not override price with 0 if there was a prior price already' do
      list_date = 1.year.ago
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date, price: 100)
      ic.create_transaction imd      
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date, price: 0)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
      ptl = pp.property_transaction_logs.first
      ptl.price.should == 100
    end

    it 'does not override price with 0 if there was a prior price already' do
      list_date = 1.year.ago
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date, price: 100)
      ic.create_transaction imd      
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date, price: nil)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
      ptl = pp.property_transaction_logs.first
      ptl.price.should == 100
    end

  end

  describe '#generate_import_diffs' do  
    context 'created' do
      context 'no previous import job' do
        it 'creates a new created import diff' do
          il = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_transacted: transacted_date,
            price: 1000
          )
          ic.generate_import_diffs ij.id
          idiff = ic.get_import_diff ij.id, il
          idiff.nil?.should == false
          idiff.diff_type.should == "created"
        end    
      end

      context 'has previous import job' do
        it 'creates a new created import diff' do
          ij
          nij = create(:import_job)
          il = create(:import_log, 
            source: "some source",        
            import_job_id: nij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_transacted: transacted_date,
            price: 1000
          )
          ic.generate_import_diffs nij.id
          pid = ic.get_previous_batch_id nij.id
          pid.should == ij.id
          idiff = ic.get_import_diff nij.id, il
          idiff.nil?.should == false
          idiff.diff_type.should == "created"
        end
      end
    end

    context 'updated' do
      context 'has previous import job' do
        it 'does not create an import diff' do
          il1 = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_transacted: transacted_date,
            price: 1000
          )

          nij = create(:import_job)
          il2 = create(:import_log, 
            source: "some source",        
            import_job_id: nij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_transacted: transacted_date,
            price: 1000
          )

          ic.generate_import_diffs nij.id

          pid = ic.get_previous_batch_id nij.id
          pid.should == ij.id
          idiff = ic.get_import_diff nij.id, il2
          idiff.nil?.should == true
        end
      end      
    end

    context 'deleted' do
      it 'creates deleted import_diff if import_log ' do
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://legit.com/this-is-good", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        nij = create(:import_job)
        ic.generate_import_diffs nij.id
        nij.import_diffs.size.should == 1
        nij.import_diffs.first.diff_type.should == "deleted"
          
      end
    end
  end

  describe '#generate_transactions' do
    it 'creates a new transaction when given a fresh import_diff with date_listed that does not map to any transactions' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )
      ic.generate_import_diffs ij.id
      ic.generate_properties ij.id
      ic.generate_transactions ij.id

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_listed.should == transacted_date.to_date
      ptt.transaction_status.should == "open"
      ptt.price.should == 1000
    end

    it 'creates a new transaction when given a fresh import_diff with date_closed that does not map to any transactions' do
      il1 = create(:import_log,
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_closed: transacted_date,
        price: 1000
      )
      ic.generate_import_diffs ij.id
      ic.generate_properties ij.id
      ic.generate_transactions ij.id

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_closed.should == transacted_date.to_date
      ptt.transaction_status.should == "closed"
      ptt.price.should == 1000
    end

    it 'closes an existing transaction if corresponding import_log is not found in new batch' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      ic.generate_import_diffs ij.id
      ic.generate_properties ij.id
      ic.generate_transactions ij.id      

      nij = create(:import_job)
      ic.generate_import_diffs nij.id
      ic.generate_properties nij.id
      ic.generate_transactions nij.id

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_closed.should == transacted_date.to_date
      ptt.transaction_status.should == "closed"
      ptt.price.should == 1000

    end    
  end

  describe '#discard?' do
    it 'returns false if price is not set properyly' do
      row = generate_row price: "0"
      ic.create_import_log row
      ImportLog.all.size.should == 0
    end

    it 'returns false if price is zero' do
      row = generate_row price: "NA"
      ic.create_import_log row
      ImportLog.all.size.should == 0
    end
    it 'returns true if price is set properyly' do
      row = generate_row price: "666"
      ic.create_import_log row
      ImportLog.all.size.should == 1      
    end

    it 'returns true if sqft is not set properyly' do
      row = generate_row sqft: "NA"
      ic.create_import_log row
      ImportLog.all.size.should == 0      
    end

    it 'returns true if price is set properyly' do
      row = generate_row sqft: "1,000"
      ic.create_import_log row
      ImportLog.all.size.should == 1      
    end

    it 'returns true if address is undisclosed' do
      row = generate_row address: "(Undisclosed Address) San Francisco, CA 94114"
      ic.create_import_log row
      ImportLog.all.size.should == 0
    end

    it 'returns true if address does not start with a number' do
      row = generate_row address: "San Francisco, CA 94114"
      ic.create_import_log row
      ImportLog.all.size.should == 0
    end    

    it 'returns false if address starts with a number' do
      row = generate_row address: "111 San Francisco, CA 94114"
      ic.create_import_log row
      ImportLog.all.size.should == 1
    end        
  end
end