require './lib/tasks/rental_creators/rental_creator'

class ZillowImporter
  include RentalCreator  

  DEFAULT_TRANSACTION_TYPE = "rental"

  def create_import_log_with_zillow_special(row)
    return if is_diry? row

    row["price"] = /[0-9,]+/.match(row["price"]).to_s
    if row["transaction_type"].nil?

      immediate_prior_transaction = ImportLog.where( 
        import_job_id: row["import_job_id"], 
        origin_url: row["origin_url"]
      ).last

      unless immediate_prior_transaction.nil?
        row["transaction_type"] = immediate_prior_transaction.transaction_type
      else
        row["transaction_type"] = "rental"
        row["transaction_type"] = "sales" if ImportFormatter.to_float( row["price"] ) > 50000
      end

    end

    new_import_log = create_import_log_without_zillow_special row
    new_import_log[:date_closed]  = ImportFormatter.to_date_short_year row["date_closed"]
    new_import_log[:date_listed]  = ImportFormatter.to_date_short_year row["date_listed"]
    new_import_log.save!

  end

  alias_method_chain :create_import_log, :zillow_special

  # returns true when this data point is dirty and should not be imported
  def is_diry? row
    /(--|xxx)/.match(row["price"])
  end


  def is_changed? old_log, new_log

    if old_log[:price] != new_log[:price]
      puts "\trecord change detected\n"
      puts "\n"
      ap old_log
      ap new_log
      return true
    else
      return false
    end
  end
  
  # The default date_listed value to be used to create a property transaction record if it does not exist
  def get_default_date_listed
    Date.today
  end

  # Returns the matching ImportLog belonging to an indicated Import Job 
  #
  # Assumption each source can only have one transaction per date with the same exact price
  def get_matching_import_log_from_batch import_log, job_id
    ImportLog.where( 
      source: import_log[:source],      
      import_job_id: job_id,
      origin_url: import_log[:origin_url],
      transaction_type: import_log[:transaction_type],
      date_transacted: import_log[:date_transacted],
      price: import_log[:price]
    ).first      
  end

  # Gets the corresponding import_diff given an import_log
  #
  # Assumption each source can only have one transaction per date with the same exact price
  def get_import_diff curr_job_id, import_log
    import_diff = ImportDiff.where( 
      source: import_log[:source],      
      import_job_id: curr_job_id,
      origin_url: import_log[:origin_url],
      transaction_type: import_log[:transaction_type],
      date_transacted: import_log[:date_transacted],
      price: import_log[:price]
    ).first    
  end

  # Creates an import diff given an import_log
  #
  # Assumption: if diff_type = deleted and if current import_log does not correspond to the most recent transaction 
  #   of indicated property, returns without creating an import_diff
  def create_import_diff( curr_import_job_id, import_log, diff_type, new_log_id, old_log_id=nil )
    to_proceed = true
    if diff_type == "deleted"
      to_proceed = most_recent_transaction_for_property_in_batch? import_log
    end
    return unless to_proceed
    super( curr_import_job_id, import_log, diff_type, new_log_id, old_log_id=nil )
  end

  # Returns true if this import_log represents the most recent transaction that occurred for a piece of property
  # listed on Zillow
  #
  # Hierarchy of logs from most recent to most dated
  #   date_listed not null
  #   date_closed not null
  def most_recent_transaction_for_property_in_batch? import_log
    most_recent = ImportLog.select(:date_transacted).where( 
      import_job_id: import_log[:import_job_id],
      origin_url: import_log[:origin_url]
    ).order(date_transacted: :desc).limit(1).first

    return false if most_recent[:date_transacted] != import_log[:date_transacted]

    logs_on_date = ImportLog.where( 
      import_job_id: import_log[:import_job_id],
      origin_url: import_log[:origin_url],
      date_transacted: import_log[:date_transacted]
    )

    return true if logs_on_date.size == 1
    return true if !import_log[:date_listed].nil?
    return false
    
  end

end
