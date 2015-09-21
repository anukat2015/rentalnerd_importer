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

  # Returns the matching ImportLog from the for a corresponding batch
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

  # TO BE OVERWRITTEN
  def get_import_diff import_log
    import_diff = ImportDiff.where( 
      source: import_log[:source],      
      import_job_id: import_log[:import_job_id],
      origin_url: import_log[:origin_url],
      transaction_type: import_log[:transaction_type],
      date_transacted: import_log[:date_transacted],
      price: import_log[:price]
    ).first    
  end

  
  def create_import_diff(import_log, diff_type, new_log_id, old_log_id=nil)
    super
  end

end
