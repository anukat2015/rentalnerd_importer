require './lib/tasks/import_formatter'

module RentalCreator

  # Supports rental or sales
  DEFAULT_TRANSACTION_TYPE = "rental"

  def get_source_from_job job_id
    source = ImportJob.where( id: job_id ).pluck(:source).first
  end

  def create_import_log(row)
    puts "\tcreating new import_log: " + row["origin_url"]
    import_log = ImportLog.create
    import_log[:address]          = row["address"]
    import_log[:neighborhood]     = row["neighborhood"]
    import_log[:bedrooms]         = ImportFormatter.to_float row["bedrooms"]
    import_log[:bathrooms]        = ImportFormatter.to_float row["bathrooms"]
    import_log[:price]            = ImportFormatter.to_float row["price"]
    import_log[:sqft]             = ImportFormatter.to_float row["sqft"]
    import_log[:date_closed]      = ImportFormatter.to_date row["date_closed"]
    import_log[:date_listed]      = ImportFormatter.to_date row["date_listed"]
    import_log[:source]           = row["source"]
    import_log[:origin_url]       = row["origin_url"]
    import_log[:import_job_id]    = row["import_job_id"]
    import_log[:transaction_type] = row["transaction_type"] || DEFAULT_TRANSACTION_TYPE
    import_log.save!
    import_log
  end

  def generate_import_diffs( curr_import_job_id )
    puts "\nProcessing import_diffs"
    generate_created_and_modified_diffs curr_import_job_id 
    generate_deleted_diffs curr_import_job_id 
  end

  def generate_created_and_modified_diffs( curr_import_job_id )
    puts "\tProcessing created, updated import_diffs"
    previous_import_job_id = self.get_previous_batch_id curr_import_job_id
    
    ImportLog.where( import_job_id: curr_import_job_id ).each do |import_log|
      
      # There was no previous batch ever imported
      if previous_import_job_id.nil? == 1
        self.create_import_diff( import_log, "created", import_log[:id] )

      # There was a previous batch ever imported
      else
        previous_log = self.get_matching_record_from_batch import_log, previous_import_job_id

        if previous_log.nil?
          # binding.pry
          puts "\t\tcould not find "+ import_log[:origin_url] +" in Job: " + previous_import_job_id.to_s
          self.create_import_diff( import_log, "created", import_log[:id], nil )

        elsif self.is_changed? previous_log, import_log
          self.create_import_diff( import_log, "updated", import_log[:id], previous_log[:id] )

        end
      end 
    end    
  end

  # To Be Completed
  def generate_deleted_diffs( curr_import_job_id )
    puts "\tProcessing deleted import_diffs"
    previous_import_job_id = self.get_previous_batch_id curr_import_job_id

    return if previous_import_job_id.nil?

    deleted_import_logs = []
    ImportLog.where( import_job_id: previous_import_job_id ).each do |prev_log|
      current_log = self.get_matching_record_from_batch prev_log, curr_import_job_id

      if current_log.nil?
        self.create_import_diff( prev_log, "deleted", nil, prev_log[:id] )
      end

    end

  end

  def get_previous_batch_id job_id
    source = get_source_from_job job_id
    previous_import_job_id = ImportJob.where(source: source).where( "id < ?", job_id ).pluck(:id).reverse.first
  end

  # Creates a new import_diff entry
  #
  # Params:
  #   import_log: ImportLog
  #   diff_type:String
  #     - created
  #     - updated
  #     - deleted
  #
  def create_import_diff(import_log, diff_type, new_log_id, old_log_id=nil)
    import_diff = ImportDiff.where( 
      origin_url: import_log[:origin_url], 
      import_job_id: import_log[:import_job_id],
      source: import_log[:source]
    ).first

    if import_diff.nil?
      puts "\trecord was #{diff_type} : " + import_log[:origin_url]
      import_diff = ImportDiff.create
      import_diff[:address]      = import_log[:address]
      import_diff[:neighborhood] = import_log[:neighborhood]
      import_diff[:bedrooms]     = import_log[:bedrooms]
      import_diff[:bathrooms]    = import_log[:bathrooms]
      import_diff[:price]        = import_log[:price]
      import_diff[:sqft]         = import_log[:sqft]
      import_diff[:date_closed]  = import_log[:date_closed]
      import_diff[:date_listed]  = import_log[:date_listed]
      import_diff[:source]       = import_log[:source]
      import_diff[:origin_url]   = import_log[:origin_url]
      import_diff[:import_job_id]        = import_log[:import_job_id]
      import_diff[:transaction_type] = import_log[:transaction_type]
      import_diff[:diff_type]    = diff_type
      import_diff[:old_log_id]    = old_log_id
      import_diff[:new_log_id]    = new_log_id
      import_diff.save!
      import_diff        
    end
  end

  def generate_properties job_id

    puts "\nProcessing properties for job #{job_id}"
    source = get_source_from_job job_id
    ImportDiff.where( import_job_id: job_id ).each do |import_diff|
      create_property import_diff
    end

  end

  def create_property import_diff

    property = get_matching_property import_diff[:origin_url]
    if property.nil?
      puts "\tNew property detected: #{import_diff[:origin_url]}\n\tSource: #{import_diff[:source]}"
      property = Property.create!(
        address:        import_diff[:address],
        neighborhood:   import_diff[:neighborhood],
        bedrooms:       import_diff[:bedrooms],
        bathrooms:      import_diff[:bathrooms],
        sqft:           import_diff[:sqft],
        source:         import_diff[:source],
        origin_url:     import_diff[:origin_url]
      )
    else
      property.address      = import_diff[:address]
      property.neighborhood = import_diff[:neighborhood]
      property.bedrooms     = import_diff[:bedrooms]
      property.bathrooms    = import_diff[:bathrooms]
      property.sqft         = import_diff[:sqft]
      property.save!
    end

  end

  def generate_transactions job_id
    puts "\nProcessing transactions for job #{job_id}"
    source = get_source_from_job job_id
    ImportDiff.where( import_job_id: job_id ).each do |import_diff|
      puts "\tGenerating new transaction: #{import_diff[:origin_url]}\n\tSource: #{import_diff[:source]}"
      create_transaction import_diff
    end
  end

  # Method to be overwritten
  # Creates the transaction
  def create_transaction import_diff
    transaction_type = import_diff["transaction_type"] || DEFAULT_TRANSACTION_TYPE
    property = get_matching_property import_diff[:origin_url]
    transaction = PropertyTransactionLog.guess property[:id], import_diff[:date_closed], import_diff[:date_listed], transaction_type

    date_listed = nil
    if import_diff[:date_closed].nil?
      date_listed = import_diff[:date_listed] || get_default_date_listed
    end

    # This transaction was never priorly captured
    if transaction.nil?
      PropertyTransactionLog.create!(
        property_id: property[:id],
        price: import_diff[:price],
        date_listed: date_listed,
        date_closed: import_diff[:date_closed],
        transaction_type: transaction_type
      )

    # This transaction was priorly captured
    else
      transaction.date_closed = import_diff[:date_closed] unless import_diff[:date_closed].nil?
      transaction.date_listed = date_listed unless date_listed.nil?
      transaction.save!
    end
  end  

  # Method to be overwritten
  # Returns the default date_listed value for creating a property transaction record if value is not available
  def get_default_date_listed
    nil
  end  

  # Method to be overwritten
  # Returns the matching transaction record
  def get_matching_transaction import_diff
    # PropertyTransactionLog.where(:)
  end

  # Method to be overwritten
  # Returns the matching property record
  def get_matching_property property_url
    Property.where( origin_url: property_url ).first
  end

  # Method to be overwritten
  # Returns the matching record from the previous batch
  def get_matching_record_from_batch import_log, job_id
    ImportLog.where( 
      origin_url: import_log[:origin_url], 
      import_job_id: job_id,
      source: import_log[:source]
    ).first      
  end

  # Method to be overwritten
  # Returns true if current record has changed as compared to same record in previous batch
  def is_changed? old_log, new_log

    true
  end


end