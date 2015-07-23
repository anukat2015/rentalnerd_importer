require './lib/tasks/import_formatter'

module RentalCreator

  def get_source_from_job job_id
    source = RentalImportJob.where( id: job_id ).pluck(:source).first
  end

  def create_rental_log(row)
    puts "\tcreating new rental_log: " + row["origin_url"]
    rental_log = RentalLog.create
    rental_log[:address]      = row["address"]
    rental_log[:neighborhood] = row["neighborhood"]
    rental_log[:bedrooms]     = ImportFormatter.to_float row["bedrooms"]
    rental_log[:bathrooms]    = ImportFormatter.to_float row["bathrooms"]
    rental_log[:price]        = ImportFormatter.to_float row["price"]
    rental_log[:sqft]         = ImportFormatter.to_float row["sqft"]
    rental_log[:date_rented]  = ImportFormatter.to_date row["date_rented"]
    rental_log[:date_listed]  = ImportFormatter.to_date row["date_listed"]
    rental_log[:source]       = row["source"]
    rental_log[:origin_url]   = row["origin_url"]
    rental_log[:rental_import_job_id]       = row["rental_import_job_id"]
    rental_log.save!
    rental_log

  end

  def generate_rental_diffs( curr_rental_import_job_id )
    puts "\nProcessing rental_diffs"
    generate_created_and_modified_diffs curr_rental_import_job_id 
    generate_deleted_diffs curr_rental_import_job_id 
  end

  def generate_created_and_modified_diffs( curr_rental_import_job_id )
    puts "\tProcessing created, updated rental_diffs"
    previous_rental_import_job_id = self.get_previous_batch_id curr_rental_import_job_id
    
    RentalLog.where( rental_import_job_id: curr_rental_import_job_id ).each do |rental_log|
      
      # There was no previous batch ever imported
      if previous_rental_import_job_id.nil? == 1
        self.create_rental_diff( rental_log, "created", rental_log[:id] )

      # There was a previous batch ever imported
      else
        previous_log = self.get_matching_record_from_batch rental_log, previous_rental_import_job_id

        if previous_log.nil?
          # binding.pry
          puts "\t\tcould not find "+ rental_log[:origin_url] +" in Job: " + previous_rental_import_job_id.to_s
          self.create_rental_diff( rental_log, "created", rental_log[:id], nil )

        elsif self.is_changed? previous_log, rental_log
          self.create_rental_diff( rental_log, "updated", rental_log[:id], previous_log[:id] )

        end
      end 
    end    
  end

  # To Be Completed
  def generate_deleted_diffs( curr_rental_import_job_id )
    puts "\tProcessing created, updated rental_diffs"
    previous_rental_import_job_id = self.get_previous_batch_id curr_rental_import_job_id

    return if previous_rental_import_job_id.nil?

    deleted_rental_logs = []
    RentalLog.where( rental_import_job_id: previous_rental_import_job_id ).each do |prev_log|
      current_log = self.get_matching_record_from_batch prev_log, curr_rental_import_job_id

      if current_log.nil?
        self.create_rental_diff( prev_log, "deleted", nil, prev_log[:id] )
      end

    end

  end

  def get_previous_batch_id job_id
    source = get_source_from_job job_id
    previous_rental_import_job_id = RentalImportJob.where(source: source).where( "id < ?", job_id ).pluck(:id).reverse.first
  end

  # Creates a new rental_diff entry
  #
  # Params:
  #   rental_log: RentalLog
  #   diff_type:String
  #     - created
  #     - updated
  #     - deleted
  #
  def create_rental_diff(rental_log, diff_type, new_log_id, old_log_id=nil)
    rental_diff = RentalDiff.where( 
      origin_url: rental_log[:origin_url], 
      rental_import_job_id: rental_log[:rental_import_job_id],
      source: rental_log[:source]
    ).first

    if rental_diff.nil?
      puts "\trecord was #{diff_type} : " + rental_log[:origin_url]
      rental_diff = RentalDiff.create
      rental_diff[:address]      = rental_log[:address]
      rental_diff[:neighborhood] = rental_log[:neighborhood]
      rental_diff[:bedrooms]     = rental_log[:bedrooms]
      rental_diff[:bathrooms]    = rental_log[:bathrooms]
      rental_diff[:price]        = rental_log[:price]
      rental_diff[:sqft]         = rental_log[:sqft]
      rental_diff[:date_rented]  = rental_log[:date_rented]
      rental_diff[:date_listed]  = rental_log[:date_listed]
      rental_diff[:source]       = rental_log[:source]
      rental_diff[:origin_url]   = rental_log[:origin_url]
      rental_diff[:rental_import_job_id]        = rental_log[:rental_import_job_id]
      rental_diff[:diff_type]    = diff_type
      rental_diff[:old_log_id]    = old_log_id
      rental_diff[:new_log_id]    = new_log_id
      rental_diff.save!
      rental_diff        
    end
  end

  def generate_properties job_id

    puts "\nProcessing properties for job #{job_id}"
    source = get_source_from_job job_id
    RentalDiff.where( rental_import_job_id: job_id ).each do |rental_diff|
      create_property rental_diff
    end

  end

  def create_property rental_diff

    property = get_matching_property rental_diff
    if property.nil?
      puts "\tNew property detected: #{rental_diff[:origin_url]}\n\tSource: #{rental_diff[:source]}"
      property = Property.create!(
        address:        rental_diff[:address],
        neighborhood:   rental_diff[:neighborhood],
        bedrooms:       rental_diff[:bedrooms],
        bathrooms:      rental_diff[:bathrooms],
        sqft:           rental_diff[:sqft],
        source:         rental_diff[:source],
        origin_url:     rental_diff[:origin_url]
      )
    end

  end

  def generate_transactions job_id
    puts "\nProcessing transactions for job #{job_id}"
    source = get_source_from_job job_id
    RentalDiff.where( rental_import_job_id: job_id ).each do |rental_diff|
      puts "\tGenerating new transaction: #{rental_diff[:origin_url]}\n\tSource: #{rental_diff[:source]}"
      create_transaction rental_diff
    end
  end

  def is_latest_transaction rental_diff
    property = get_matching_property rental_diff
    RentalTransaction.where(property_id: property[:id]).each do |curr_transaction|

      if !curr_transaction[:date_rented].nil? &&
        !rental_diff[:date_rented].nil? && 
        curr_transaction[:date_rented]  > rental_diff[:date_rented]
        return false
      end

      if !curr_transaction[:date_rented].nil? &&
        !rental_diff[:date_listed].nil? && 
        curr_transaction[:date_rented]  > rental_diff[:date_listed]
        return false
      end

      if !curr_transaction[:date_listed].nil? &&
        !rental_diff[:date_rented].nil? && 
        curr_transaction[:date_listed]  > rental_diff[:date_rented]
        return false
      end

      if !curr_transaction[:date_listed].nil? &&
        !rental_diff[:date_listed].nil? && 
        curr_transaction[:date_listed]  > rental_diff[:date_listed]
        return false
      end            
    end

    return true
  end

  # Method to be overwritten
  # Creates the transaction
  def create_transaction rental_diff
  end

  # Method to be overwritten
  # Returns the matching transaction record
  def get_matching_transaction rental_diff
    # RentalTransaction.where(:)
  end

  # Method to be overwritten
  # Returns the matching property record
  def get_matching_property rental_diff
    Property.where( origin_url: rental_diff[:origin_url], source: rental_diff[:source] ).first
  end

  # Method to be overwritten
  # Returns the matching record from the previous batch
  def get_matching_record_from_batch rental_log, job_id
    nil
  end

  # Method to be overwritten
  # Returns true if current record has changed as compared to same record in previous batch
  def is_changed? old_log, new_log

    true
  end


end