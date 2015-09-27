require 'spec_helper'
require './lib/tasks/rental_creators/zillow_importer'

RSpec.describe ZillowImporter do
  let(:zi) { ZillowImporter.new }
  let(:ij) { create(:import_job) }
  let(:transacted_date) { Time.now }


  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    zi.stub(:get_default_date_listed) { default_time }
    google_map_request
  end  
  
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
      found_idiff = zi.get_import_diff ij.id, il
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
      found_idiff = zi.get_import_diff ij.id, il
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
      found_idiff = zi.get_import_diff ij.id, il
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
      found_idiff = zi.get_import_diff ij.id, il
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
          idiff = zi.get_import_diff ij.id, il
          idiff.nil?.should == false
          idiff.diff_type.should == "created"
        end

        it 'creates 2 new created import diff' do
          il1 = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "some url", 
            transaction_type: "rental",
            date_listed: transacted_date,
            date_transacted: transacted_date,
            price: 1000
          )
          closed_date = transacted_date + 1.day
          il2 = create(:import_log, 
            source: "some source",        
            import_job_id: ij.id,
            origin_url: "some url", 
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
            origin_url: "some url", 
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

  describe '#generate_transactions' do
    it 'creates a new transaction when given a fresh import_diff with date_listed that does not map to any transactions' do
      il1 = create(:import_log, 
        source: "some source",        
        import_job_id: ij.id,
        origin_url: "some url", 
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
        origin_url: "some url", 
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
        origin_url: "some url", 
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
        origin_url: "some url", 
        transaction_type: "rental",
        date_transacted: transacted_date,
        date_listed: transacted_date,
        price: 1000
      )      
      il3 = create(:import_log,
        source: "some source",
        import_job_id: nij.id,
        origin_url: "some url", 
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
        origin_url: "some url", 
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

  end

end 

