require 'spec_helper'
require './lib/tasks/rental_creators/zillow_importer'



RSpec.describe ZillowImporter do
  let(:zi) { ZillowImporter.new }
  let(:ij) { create(:import_job) }
  let(:transacted_date) { Time.now }
  
  describe '#get_matching_import_log_from_batch' do
    it 'returns a matching import log' do
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.should == il
    end

    it 'returns nil date_transacted does not match' do
      transacted_date = Time.now
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il.date_transacted = 1.year.ago

      found_il = zi.get_matching_import_log_from_batch il, ij.id
      found_il.nil?.should == true
    end    
  end

  describe '#get_import_diff', :found do
    it 'returns corresponding import_diff' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(il, "rental", il.id, nil)
      found_idiff = zi.get_import_diff il
      found_idiff.should == idiff
    end

    it 'returns nil if could not find corresponding import_diff' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(il, "rental", il.id, nil)

      il[:date_transacted] = 1.year.ago
      found_idiff = zi.get_import_diff il
      found_idiff.nil?.should == true
    end
  end

  describe '#create_import_diff' do
    it 'creates import_diff if is diff_type is created'
    it 'creates import_diff if is diff_type is updated'
    it 'creates import_diff if is diff_type is deleted and import_log is the most recent entry for property'
    it 'does not creates import_diff if is diff_type is deleted and import_log is not the most recent entry for property'
  end
end 