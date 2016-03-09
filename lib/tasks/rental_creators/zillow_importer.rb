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
      is_most_recent = most_recent_transaction_for_property_in_batch? import_log
      is_scam = purge_scam!( import_log["origin_url"] )
      if is_scam
        is_closed = false
      else
        is_closed = is_really_closed?( import_log['transaction_type'], import_log["origin_url"] )
      end
      to_proceed = is_most_recent && !is_scam && is_closed
    end
    return unless to_proceed
    super( curr_import_job_id, import_log, diff_type, new_log_id, old_log_id=nil )
  end

  def purge_scam!( origin_url)
    is_scam = scam?( origin_url )
    
    if is_scam
      puts "\tdiscarding scam record for: " + origin_url
      Property.purge_records( origin_url ) 
      ImportLog.purge_records( origin_url ) 
      ImportDiff.purge_records( origin_url ) 
    end 
    is_scam   
  end

  # Returns true if this import_log represents the most recent transaction that occurred for a piece of property
  # listed on Zillow
  #
  # Hierarchy of logs from most recent to most dated
  #   date_listed not null
  #   date_closed not null
  def most_recent_transaction_for_property_in_batch?( import_log )
    most_recent = ImportLog.select(:date_transacted).where( 
      import_job_id: import_log[:import_job_id],
      origin_url: import_log[:origin_url]
    ).order(date_transacted: :desc).limit(1).first

    # Returns false if the import_log does not have the same date_transacted as the most recent log in record
    if most_recent.nil?
      raise "cannot find any corresponding import_log in batch"
    elsif most_recent.present? && most_recent[:date_transacted] != import_log[:date_transacted]
      return false

    # transaction date matches to the most recent one
    elsif most_recent.present? && most_recent[:date_transacted] == import_log[:date_transacted]
      return true
    end

  end

  def scam?( url )
    uri = URI( url)
    res = Net::HTTP.get_response(uri)
    if res.code == "200"
      return false
    elsif res.code == "301"
      return true
    end
    return false
  end

  def purge_scam_records( scam_url )
    Property.destroy_all( origin_url: scam_url )
  end

  def check_property_transaction_log_for_false_positive( ptl_id )
    ptl = PropertyTransactionLog.find_by_id( ptl_id )

    return if ptl.nil?
    puts "Property Transaction Log (ID:#{ptl.id}), type:#{ptl.transaction_type}, price: #{ptl.price} "

    if purge_scam!(ptl.property.origin_url)
      puts "\tWe detected a scam"

    elsif ptl.is_latest_transaction_on_page?()
      should_close = is_really_closed? ptl.transaction_type, ptl.property.origin_url
      if !should_close 
        puts "\tProperty Transaction Log (ID: #{ptl_id}) Detected false positive!"
        puts "\t\tOrigin date_closed: #{ptl.date_closed}"
        ptl.date_closed = nil
      end
      ptl.save!
    else
      puts "\tIs not the latest transaction on the page"
    end

  end

  def is_really_closed?( transaction_type, url )
    property_status = current_property_page_status url
    puts "\tActual zillow\n\t\tproperty: #{url} \n\t\tstatus: #{property_status}"
    case transaction_type
    when "rental"
      if /Sold/.match(property_status)
        true
      elsif /Off Market/.match(property_status)
        true
      elsif /For Sale/.match(property_status)
        true
      elsif /Pending/.match(property_status)
        true
      elsif /For Rent/.match(property_status)
        false
      elsif /Coming Soon/.match(property_status)
        true
      elsif /Foreclosure/.match(property_status)
        true    
      elsif /Foreclosed/.match(property_status)
        true    
      elsif /New Construction/.match(property_status)
        false
      elsif /Land/.match(property_status)
        false
      else
        raise "Unknown zillow transaction_type: #{transaction_type} property_status_type: #{property_status}"
      end

    when "sales"
      if /Sold/.match(property_status)
        true
      elsif /Off Market/.match(property_status)
        true
      elsif /Pending/.match(property_status)
        true        
      elsif /For Sale/.match(property_status)
        false
      elsif /Coming Soon/.match(property_status)
        false      
      elsif /Foreclosure/.match(property_status)
        false
      elsif /Foreclosed/.match(property_status)
        false
      elsif /New Construction/.match(property_status)
        false
      elsif /For Rent/.match(property_status)
        true
      elsif /Land/.match(property_status)
        false
      else
        raise "Unknown zillow transaction_type: #{transaction_type} property_status_type: #{property_status}"
      end
    else
      raise "Unknown zillow transaction_type: #{transaction_type} property_status_type: #{property_status}"
    end
  rescue
    warner = SlackFatalErrorWarning.new
    message = "Unknown zillow transaction_type: #{transaction_type} property_status_type: #{property_status}"
    warner.perform message
    false    
  end

  def current_property_page_status( url )
    page = Nokogiri::HTML( HTTParty.get( url ) )
    status_div = page.css(".status-icon-row").first
    if status_div.present?
      status_div.text.strip()
    else
      nil
    end
  end    

end
