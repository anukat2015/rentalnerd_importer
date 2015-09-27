require 'spec_helper'
require './lib/tasks/rental_creators/rental_creator'
require './lib/tasks/rental_creators/climbsf_renting_importer'

RSpec.describe ClimbsfRentingImporter do

  let(:ic) { ClimbsfRentingImporter.new }
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
      "address" => "some address", 
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

  describe '#generate_import_diffs' do  
    context 'created' do
      context 'no previous import job' do
        it 'creates a new created import diff' do
          il = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "some url", 
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
            origin_url: "some url", 
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
            origin_url: "some url", 
            transaction_type: "rental",
            date_transacted: transacted_date,
            price: 1000
          )

          nij = create(:import_job)
          il2 = create(:import_log, 
            source: "some source",        
            import_job_id: nij.id,
            origin_url: "some url", 
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
            origin_url: "some url", 
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
end