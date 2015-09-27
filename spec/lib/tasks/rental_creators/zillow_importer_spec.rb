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

    it 'returns nil when date_transacted does not match' do
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

    it 'returns nil when price does not match' do
      transacted_date = Time.now
      il = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
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
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il.transaction_type = "sales"

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
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)
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
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:date_transacted] = 1.year.ago
      found_idiff = zi.get_import_diff il
      found_idiff.nil?.should == true
    end

    it 'returns nil when price does not match' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:price] = 2000
      found_idiff = zi.get_import_diff il
      found_idiff.nil?.should == true      
    end

    it 'returns nil when transaction_type does not match' do
      il = create(:import_log, 
        source: "some source",
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )
      idiff = zi.create_import_diff(ij.id, il, "rental", il.id, nil)

      il[:transaction_type] = "sale"
      found_idiff = zi.get_import_diff il
      found_idiff.nil?.should == true      
    end
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
          zi.generate_import_diffs ij.id
          idiff = zi.get_import_diff il
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
          zi.generate_import_diffs nij.id
          pid = zi.get_previous_batch_id nij.id
          pid.should == ij.id
          idiff = zi.get_import_diff il
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

          zi.generate_import_diffs nij.id

          pid = zi.get_previous_batch_id nij.id
          pid.should == ij.id

          idiff = zi.get_import_diff il2
          idiff.nil?.should == true
        end
      end      
    end

    context 'deleted' do
      it 'creates deleted import_diff if import_log is the most recent entry for property' do
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "some url", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        nij = create(:import_job)
        zi.generate_import_diffs nij.id
        nij.import_diffs.size.should == 1
        nij.import_diffs.first.diff_type.should == "deleted"
      end

      it 'only creates import_diff for a property using the latest transaction for a property' do 
        il1 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "some url", 
          transaction_type: "rental",
          date_transacted: transacted_date,
          price: 1000
        )

        il2 = create(:import_log, 
          source: "some source",        
          import_job_id: ij.id,
          origin_url: "some url", 
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
        origin_url: "some url", 
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
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
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
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date + 1.day,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == false      
    end

    it 'returns true if import log does not the most recent date for a property in a batch with many other properties' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
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
        origin_url: "some url", 
        transaction_type: "rental",
        date_listed: transacted_date,
        date_transacted: transacted_date,
        price: 1000
      )

      il2 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
        transaction_type: "rental",
        date_closed: transacted_date,
        date_transacted: transacted_date,
        price: 1000
      )      
      most_recent = zi.most_recent_transaction_for_property_in_batch? il1
      most_recent.should == true            
    end
  end
end 



























