require 'net/http'
require './lib/tasks/rental_creators/rental_creator'

class ZillowImporter
  include RentalCreator  

  DEFAULT_TRANSACTION_TYPE = "rental"

  def create_import_log_with_zillow_special(row)
    return if is_diry? row
    row["garage"] = false
    row["garage"] = row["parking"].include? "Garage" unless row["parking"].nil?
    row["year_built"] = row["year built"].to_i unless row["year built"].to_i == 0

    row["price"] = /[0-9,]+/.match(row["price"]).to_s

    # When Price change, Back on market or Listing removed
    if row["transaction_type"].nil?
      row["transaction_type"] = "rental"
      row["transaction_type"] = "sales" if ImportFormatter.to_float( row["price"] ) > 30000
    end

    new_import_log = create_import_log_without_zillow_special row

    if new_import_log.present?
      new_import_log[:date_closed]  = ImportFormatter.to_date row["date_closed"]
      new_import_log[:date_listed]  = ImportFormatter.to_date row["date_listed"]
      new_import_log[:date_transacted]  = new_import_log[:date_closed] || new_import_log[:date_listed]
      new_import_log.save!

    end
  end

  alias_method_chain :create_import_log, :zillow_special

  # To be overwritten: Determines if record corresponds to a single family home
  #
  # Params: 
  #   CSV::ROW
  #
  # Returns:
  #   Boolean
  #
  def is_single_family?( csv_row )
    csv_row["sfh"] == "Single Family"
  end

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
      import_job_id: job_id,
      origin_url: import_log[:origin_url],
      source: import_log[:source],            
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
      import_job_id: curr_job_id,
      origin_url: import_log[:origin_url],
      source: import_log[:source],      
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

      is_scam = scam?( import_log["origin_url"] )
      
      if is_scam
        puts "\tdiscarding scam record for: " + import_log["origin_url"]
        Property.purge_records( import_log["origin_url"] ) 
        ImportLog.purge_records( import_log["origin_url"] ) 
        ImportDiff.purge_records( import_log["origin_url"] ) 
      end

      to_proceed = to_proceed && !is_scam
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

    return false if most_recent.present? && most_recent[:date_transacted] != import_log[:date_transacted]

    logs_on_date = ImportLog.where( 
      import_job_id: import_log[:import_job_id],
      origin_url: import_log[:origin_url],
      date_transacted: import_log[:date_transacted]
    )

    return true if logs_on_date.size == 1
    return true if !import_log[:date_listed].nil?
    return false

  end

  def scam? url
    uri = URI( url)
    res = Net::HTTP.get_response(uri)
    if res.code == "200"
      return false
    elsif res.code == "301"
      return true
    end
    return false
  end

  def purge_scam_records scam_url
    Property.destroy_all( origin_url: scam_url )
  end

end
