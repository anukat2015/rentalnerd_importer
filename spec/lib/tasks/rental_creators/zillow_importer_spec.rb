require 'spec_helper'
require './lib/tasks/rental_creators/zillow_importer'

RSpec.describe ZillowImporter do
  let(:zi) { ZillowImporter.new }
  let(:ij) { create(:import_job) }
  let(:transacted_date) { Time.now }

  def csv_headers
    headers = [
      "address", 
      "neighborhood", 
      "bedrooms", 
      "bathrooms", 
      "price", 
      "sqft", 
      "parking",
      "year built",      
      "source", 
      "origin_url", 
      "import_job_id", 
      "transaction_type", 
      "date_closed", 
      "date_listed"
    ]
  end

  def default_attributes
    default_attrs = {
      "address" => "111 some address", 
      "neighborhood" => "some neighborhood", 
      "bedrooms" => "5", 
      "bathrooms" => "5", 
      "price" => "100", 
      "sqft" => "50", 
      "parking" => nil, 
      "year built" => nil,
      "source" => "lalaland", 
      "origin_url" => "http://google.com", 
      "import_job_id" => "1",
      "transaction_type" => "rental", 
      "date_closed" => nil, 
      "date_listed" => nil,
      "event_date"  => "12/30/15"
    }.with_indifferent_access
  end

  def generate_row attrs={}
    combined_attrs = attrs.reverse_merge default_attributes
    row_array = csv_headers.map { |key| combined_attrs[key] }
    row = CSV::Row.new(csv_headers, row_array)
  end

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  def zillow_check_request
    stub_request(:get, /.*zillow.com.*for_rent.*/).to_return(:status => 200, :body => rni_fixture("zillow_for_rent.html"), :headers => {})
    stub_request(:get, /.*zillow.com.*for_sale.*/).to_return(:status => 200, :body => rni_fixture("zillow_for_sale.html"), :headers => {})
    stub_request(:get, /.*zillow.com.*pending.*/).to_return(:status => 200, :body => rni_fixture("zillow_pending.html"), :headers => {})
    stub_request(:get, /.*zillow.com.*off_market.*/).to_return(:status => 200, :body => rni_fixture("zillow_off_market.html"), :headers => {})
    stub_request(:get, /.*zillow.com.*sold.*/).to_return(:status => 200, :body => rni_fixture("zillow_sold.html"), :headers => {})
  end

  def scam_check_request
    stub_request(:get, "http://scam.com/this-is-bad").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'scam.com', 'User-Agent'=>'Ruby'}).
      to_return(:status => 301, :body => "", :headers => {})

    stub_request(:get, "http://legit.com/this-is-good").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'legit.com', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

    stub_request(:get, "http://legit.com/it-crashed").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'legit.com', 'User-Agent'=>'Ruby'}).
      to_return(:status => 500, :body => "", :headers => {})

  end

  before do
    zi.stub(:get_default_date_listed) { default_time }
    google_map_request
    scam_check_request
    zillow_check_request
  end  

  describe '#create_import_log' do
    it 'creates an import log using transaction_type indicated' do
      event_date = Time.now.strftime("%m/%d/%y")
      row = generate_row event_date: event_date, date_listed: event_date, date_transacted: event_date, transaction_type: "sales"
      zi.create_import_log row
      ImportLog.all.size.should == 1
      ImportLog.all.first.transaction_type.should == "sales"
    end

    it 'creates an import log setting transaction_type as rental if it does not have a transaction_type and has price less than 30000' do
      event_date = ( Time.now - 1.year ).strftime("%m/%d/%y")
      row1 = generate_row event_date: event_date, date_listed: event_date, date_transacted: event_date, transaction_type: "sales"
      zi.create_import_log row1

      event_date = ( Time.now ).strftime("%m/%d/%y")
      row2 = generate_row event_date: event_date, date_listed: event_date, date_transacted: event_date, price: "29999"
      row2["transaction_type"] = nil
      zi.create_import_log row2
      ImportLog.all.size.should == 2
      ImportLog.all.first.transaction_type.should == "sales"
      ImportLog.all.second.transaction_type.should == "rental"
    end

    it 'creates an import log setting transaction_type as sales if it does not have a transaction_type and has price above 30000' do
      event_date = ( Time.now - 1.year ).strftime("%m/%d/%y")
      row1 = generate_row event_date: event_date, date_listed: event_date, date_transacted: event_date, transaction_type: "rental"
      zi.create_import_log row1

      event_date = ( Time.now ).strftime("%m/%d/%y")
      row2 = generate_row event_date: event_date, date_listed: event_date, date_transacted: event_date, price: "30001"
      row2["transaction_type"] = nil
      zi.create_import_log row2
      ImportLog.all.size.should == 2
      ImportLog.all.first.transaction_type.should == "rental"
      ImportLog.all.second.transaction_type.should == "sales"
    end

    it 'sets year built to actual value if it exist' do
      row = generate_row "year built" => "1995"
      zi.create_import_log row
      il = ImportLog.all.first
      il.year_built.should == 1995
    end

    it 'sets year built to null if it is null' do
      row = generate_row "year built" => nil
      zi.create_import_log row
      il = ImportLog.all.first
      il.year_built.should == nil
    end

    it 'sets garage to actual value if it exist' do
      row = generate_row parking: "Garage - Attached, On street, 1 space"
      zi.create_import_log row
      il = ImportLog.all.first
      il.garage.should == true
    end

    it 'sets garage to null if it is null' do
      row = generate_row parking: nil
      zi.create_import_log row
      il = ImportLog.all.first
      il.garage.should == false
    end

  end  
  
  describe '#get_matching_import_log_from_batch' do
    it 'returns a matching import log' do
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.should == il
    end

    it 'returns nil when date_transacted does not match' do
      transacted_date = Time.now
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il.date_transacted = 1.year.ago

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.nil?.should == true
    end

    it 'returns nil when price does not match' do
      transacted_date = Time.now
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il.price = 2000

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.nil?.should == true
    end

    it 'returns nil when transaction_type does not match' do
      transacted_date = Time.now
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il.transaction_type = "sales"

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.nil?.should == true      
    end
  end

  describe '#get_import_diff' do
    it 'returns corresponding import_diff' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://zillow.com/off_market", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)
      found_idiff = zi.get_import_diff ij.id, il
      found_idiff.should == idiff
    end

    it 'returns nil if could not find corresponding import_diff' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:date_transacted] = 1.year.ago
      found_idiff = zi.get_import_diff ij.id, il
      found_idiff.nil?.should == true
    end

    it 'returns nil when price does not match' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:price] = 2000
      found_idiff = zi.get_import_diff ij.id, il
      found_idiff.nil?.should == true      
    end

    it 'returns nil when transaction_type does not match' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:transaction_type] = "sales"
      found_idiff = zi.get_import_diff ij.id, il
      found_idiff.nil?.should == true      
    end

    it 'sets garage to garage of import_log if that was set' do
      il = create(:import_log, garage: true)
      zi.create_import_diff( 666, il, "created", 555)
      idiff = ImportDiff.all.first
      idiff.garage.should == true
    end

    it 'sets garage to nil if import_log.garage was not set' do
      il = create(:import_log, garage: nil)
      zi.create_import_diff( 666, il, "created", 555)
      idiff = ImportDiff.all.first
      idiff.garage.should == nil      
    end

    it 'sets year_built to year_built of import_log if that was set' do
      il = create(:import_log, year_built: 1995)
      zi.create_import_diff( 666, il, "created", 555)
      idiff = ImportDiff.all.first
      idiff.year_built.should == 1995
    end

    it 'sets year_built to nil if import_log.year_built was not set' do
      il = create(:import_log, year_built: nil)
      zi.create_import_diff( 666, il, "created", 555)
      idiff = ImportDiff.all.first
      idiff.year_built.should == nil
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
          zi.generate_import_diffs ij.id
          idiff = zi.get_import_diff ij.id, il
          idiff.nil?.should == false
          idiff.diff_type.should == "created"
        end

        it 'creates 2 new created import diff' do
          il1 = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_listed: transacted_date,
            date_transacted: transacted_date,
            price: 1000
          )
          closed_date = transacted_date + 1.day
          il2 = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "http://legit.com/this-is-good", 
            transaction_type: "rental",
            date_closed: closed_date,
            date_transacted: closed_date,
            price: 1000
          )          
          zi.generate_import_diffs ij.id

          ij.import_diffs.size.should == 2

          idiff1 = zi.get_import_diff ij.id, il1
          idiff1.nil?.should == false
          idiff1.date_listed.should == transacted_date.to_date
          idiff1.diff_type.should == "created"

          idiff2 = zi.get_import_diff ij.id, il2
          idiff2.nil?.should == false
          idiff2.date_closed.should == closed_date.to_date
          idiff2.diff_type.should == "created"          
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
          zi.generate_import_diffs nij.id
          pid = zi.get_previous_batch_id nij.id
          pid.should == ij.id
          idiff = zi.get_import_diff nij.id, il
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

          zi.generate_import_diffs nij.id

          pid = zi.get_previous_batch_id nij.id
          pid.should == ij.id

          idiff = zi.get_import_diff nij.id, il2
          idiff.nil?.should == true
        end
      end      
    end

    context 'deleted' do
      it 'creates deleted import_diff if import_log is the most recent entry for property' do
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://zillow.com/off_market", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        nij = create(:import_job)
        zi.generate_import_diffs nij.id
        nij.import_diffs.size.should == 1
        nij.import_diffs.first.diff_type.should == "deleted"
      end

      it 'does not create deleted import_diff rental type if For Rent is still on in the web page' do
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://zillow.com/for_rent", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        nij = create(:import_job)
        zi.generate_import_diffs nij.id
        nij.import_diffs.size.should == 0
      end      

      it 'does not create deleted import_diff rental type if For Sale is still on in the web page' do
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://zillow.com/for_sale", 
          transaction_type: "sales",
          date_transacted: transacted_date,
          price: 1000
        )

        nij = create(:import_job)
        zi.generate_import_diffs nij.id
        nij.import_diffs.size.should == 0
      end            

      it 'only creates import_diff for a property using the latest transaction for a property' do 
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://zillow.com/sold", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        il2 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "http://zillow.com/sold", 
          transaction_type: "rental",
          date_transacted: transacted_date + 1.day,
          price: 2000
        )        

        nij = create(:import_job)
        zi.generate_import_diffs nij.id
        nij.import_diffs.size.should == 1
        nij.import_diffs.first.diff_type.should == "deleted"        
      end
    end

  end

  describe '#most_recent_transaction_for_property_in_batch?' do
    it 'returns true if it is the only import_log for an import_job for a property' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == true
    end

    it 'returns true if it is the import log with the most recent date for a property' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date + 1.day,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il2
      most_recent.should == true      
    end

    it 'returns false if import log does not the most recent date for a property' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date + 1.day,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == false      
    end

    it 'returns true if import log does not match the most recent date for a property in a batch with many other properties' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some other url", 
        transaction_type: "rental",
        date_transacted: transacted_date + 1.day,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == true      
    end

    it 'returns true if import log has date_listed versus another with date_closed that got transacted on the same date' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_listed: transacted_date,
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_closed: transacted_date,
        date_transacted: transacted_date,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == true            
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
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

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
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_closed.should == transacted_date.to_date
      ptt.transaction_status.should == "closed"
      ptt.price.should == 1000
    end

    it 'closes an existing transaction when closed on the same date but on different batches' do
      il1 = create(:import_log,
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

      closed_date = transacted_date + 1.day
      nij = create(:import_job)
      il2 = create(:import_log,
        source: "some source",
        import_job_id: nij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )      
      il3 = create(:import_log,
        source: "some source",
        import_job_id: nij.id,
        origin_url: "http://legit.com/this-is-good", 
        transaction_type: "rental",
        date_transacted: closed_date,
        date_closed: closed_date,
        price: 1000
      )
      zi.generate_import_diffs nij.id
      zi.generate_properties nij.id
      zi.generate_transactions nij.id      

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_listed.should == transacted_date.to_date
      ptt.date_closed.should == closed_date.to_date
      ptt.transaction_status.should == "closed"
      ptt.price.should == 1000
    end    

    it 'closes an existing transaction when deletion was detected in a subsequent batch' do
      il1 = create(:import_log,
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://zillow.com/off_market", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

      nij = create(:import_job)
      zi.generate_import_diffs nij.id
      zi.generate_properties nij.id
      zi.generate_transactions nij.id      

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_listed.should == transacted_date.to_date
      ptt.date_closed.nil?.should == false
      ptt.transaction_status.should == "closed"
      ptt.price.should == 1000
    end

    it 'does not closes an existing transaction when For Rent is still happening on Zillow' do
      il1 = create(:import_log,
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://zillow.com/for_rent", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

      nij = create(:import_job)
      zi.generate_import_diffs nij.id
      zi.generate_properties nij.id
      zi.generate_transactions nij.id      

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_listed.should == transacted_date.to_date
      ptt.date_closed.nil?.should == true
      ptt.transaction_status.should == "open"
      ptt.price.should == 1000
    end

    it 'does not closes an existing transaction when For Sale is still happening on Zillow' do
      il1 = create(:import_log,
        source: "some source",
        import_job_id: ij.id,
        origin_url: "http://zillow.com/for_sale", 
        transaction_type: "sales",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )
      zi.generate_import_diffs ij.id
      zi.generate_properties ij.id
      zi.generate_transactions ij.id

      nij = create(:import_job)
      zi.generate_import_diffs nij.id
      zi.generate_properties nij.id
      zi.generate_transactions nij.id      

      PropertyTransactionLog.all.size.should == 1
      ptt = PropertyTransactionLog.all.first
      ptt.date_listed.should == transacted_date.to_date
      ptt.date_closed.nil?.should == true
      ptt.transaction_status.should == "open"
      ptt.price.should == 1000
    end

  end

  describe '#scam?' do
    it 'returns true if response header is 301' do
      zi.scam?('http://scam.com/this-is-bad').should == true
    end
    it 'returns false if response header is 200' do
      zi.scam?('http://legit.com/this-is-good').should == false
    end
    it 'returns false if response header is 500' do
      zi.scam?('http://legit.com/it-crashed').should == false
    end    

  end

  describe '#create_property' do
    it 'sets the year_built from import_diff - 1995' do
      idiff = create(:import_diff, year_built: 1995)
      zi.create_property idiff
      pp = Property.all.first
      pp.year_built.should == 1995
    end

    it 'sets the year_built from import_diff - nil' do
      idiff = create(:import_diff, year_built: nil)
      zi.create_property idiff
      pp = Property.all.first
      pp.year_built.should == nil
    end    

    it 'sets the garage from import_diff - true' do
      idiff = create(:import_diff, garage: true)
      zi.create_property idiff
      pp = Property.all.first
      pp.garage.should == true
    end

    it 'sets the garage from import_diff - false' do
      idiff = create(:import_diff, garage: false)
      zi.create_property idiff
      pp = Property.all.first
      pp.garage.should == false
    end    
  end

  describe '#is_really_closed?' do
    context "rental" do
      it "for_rental" do
        zi.is_really_closed?('rental', 'http://zillow.com/for_rent').should == false
      end

      it "for_sale" do
        zi.is_really_closed?('rental', 'http://zillow.com/for_sale').should == true
      end

      it "off_market" do
        zi.is_really_closed?('rental', 'http://zillow.com/off_market').should == true
      end

      it "pending" do
        zi.is_really_closed?('rental', 'http://zillow.com/pending').should == true
      end

      it "sold" do
        zi.is_really_closed?('rental', 'http://zillow.com/sold').should == true
      end
    end

    context "sales" do

      it "for_sale" do
        zi.is_really_closed?('sales', 'http://zillow.com/for_sale').should == false
      end

      it "off_market" do
        zi.is_really_closed?('sales', 'http://zillow.com/off_market').should == true
      end

      it "pending" do
        zi.is_really_closed?('sales', 'http://zillow.com/pending').should == true
      end

      it "sold" do
        zi.is_really_closed?('sales', 'http://zillow.com/sold').should == true
      end
    end    

  end

end 

