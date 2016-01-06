require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_rented_importer'
require './lib/tasks/getdata_downloader'

class DataImporter
  def import_climbsf_rented
    counter = 0
    datasource_url = "http://data.getdata.io/n34_d7704e8247e565c7d2bd6705148bd338eses/csv"
    temp_file = GetdataDownloader.get_file datasource_url

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "climbsf_rented"
    )
    cri = ClimbsfRentedImporter.new

    row_count = 0
    clean_row_count = 0
    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      row["source"] = "climbsf_rented"
      row["origin_url"] = row["apartment page"]
      row["date_closed"] = row["date_rented"]
      row["import_job_id"] = job.id
      puts "\n\tprocessing row: #{$.}"
      created = cri.create_import_log row

      clean_row_count += 1 if created.present?
      row_count += 1
    end
    job.update(clean_rows: clean_row_count )
    job.update(total_rows: row_count )

    puts "\n\n\n"

    cri.generate_import_diffs job.id
    cri.generate_properties job.id
    cri.generate_transactions job.id
    temp_file.close!    
  end

  def import_climbsf_renting
    counter = 0
    datasource_url = "http://data.getdata.io/n33_f22b4acef257bfa904d548ef21050ca1eses/csv"
    temp_file = GetdataDownloader.get_file datasource_url

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "climbsf_renting"
    )
    cri = ClimbsfRentingImporter.new

    row_count = 0
    clean_row_count = 0

    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      row["source"] = "climbsf_renting"
      row["origin_url"] = row["apartment page"]
      row["import_job_id"] = job.id
      puts "\n\tprocessing row: #{$.}"
      created = cri.create_import_log row
      clean_row_count += 1 if created.present?
      row_count += 1      
    end
    job.update(clean_rows: clean_row_count )
    job.update(total_rows: row_count )    

    puts "\n\n\n"

    cri.generate_import_diffs job.id
    cri.generate_properties job.id
    cri.generate_transactions job.id
    temp_file.close!        
  end

  def import_zillow_ph
    source_name = "zillow_ph"
    source_url = "http://data.getdata.io/n53_70da17e3370067399d5095287282d302eses/csv"
    import_zillow source_name, source_url
  end

  def import_zillow_sf
    source_name = "zillow_sf"
    source_url = "http://data.getdata.io/n46_b5aee320718b31d44407ddde5ed62909eses/csv"
    import_zillow source_name, source_url   
  end  

  def import_zillow_alameda_county
    source_name = "zillow_alameda_county"
    source_url = "http://data.getdata.io/n86_19de2d95d00239a0c9263ec9252b66bbeses/csv"
    import_zillow source_name, source_url
  end

  def set_zillow_garage source_url
    puts "Processing #{source_url}"
    temp_file = GetdataDownloader.get_file source_url
    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      puts "Processing #{row['apartment page']}"
      has_garage = false
      has_garage = row["parking"].include? "Garage" unless row["parking"].nil?
      Property.where( origin_url: row["apartment page"] ).update_all( garage: has_garage )
    end
  end

  def set_zillow_year_built source_url
    puts "Processing #{source_url}"
    temp_file = GetdataDownloader.get_file source_url
    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      puts "\tProcessing #{row['apartment page']}"
      year_built = nil
      year_built = row["year built"].to_i unless row["year built"].to_i == 0
      Property.where( origin_url: row["apartment page"] ).update_all( year_built: year_built )
    end
  end

  def import_zillow source_name, source_url
    counter = 0
    datasource_url = source_url
    temp_file = GetdataDownloader.get_file datasource_url

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: source_name
    )

    zi = ZillowImporter.new

    rows = []

    row_count = 0
    clean_row_count = 0
    bad_records = []

    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|      
      row["address"] = row["address"].gsub("Incomplete address or missing price?Sometimes listing partners send Zillow listings that do not include a full address or price.To get more details on this property, please contact the listing agent, brokerage, or listing provider.", "")
      row["source"] = source_name
      row["origin_url"] = row["apartment page"]
      row["import_job_id"] = job.id
      row["sqft"] = row["size"]
      row["transaction_type_raw"] = row["transaction_type"]
      row["transaction_type"] = nil

      case row["event_name"]
      when "Listed for rent"
        row["price"]            = row["event_price"] 
        row["date_listed"]      = row["event_date"]
        row["transaction_type"] = "rental"

      when "Price change"
        row["price"]        = row["event_price"]
        row["date_listed"]  = row["event_date"]

      when "Back on market"
        row["price"]        = row["event_price"]
        row["date_listed"]  = row["event_date"]        

      when /sold/i
        row["price"]            = row["event_price"] 
        row["date_closed"]      = row["event_date"]
        row["transaction_type"] = "sales"

      when /sale/i
        row["price"]            = row["event_price"] 
        row["date_listed"]      = row["event_date"]
        row["transaction_type"] = "sales"

      when "Listing removed"
        row["price"]        = row["event_price"] 
        row["date_closed"]  = row["event_date"]
        row["date_listed"]  = row["event_date"]
      end
      
      row["event_date"]       = ImportFormatter.to_date_short_year row["event_date"]      
      
      row_count += 1
      puts "\n\tprocessing row : #{row_count}"
      # If record is of type we want
      if accept_zillow_row row
        puts "\t\tadding qualified record for: " + row["origin_url"]
        clean_row_count += 1        
        rows << row

      # If record is not of type we want
      else 
        puts "\t\tdiscarding disqualified record for: " + row["origin_url"]
        bad_records << row["origin_url"]
      end
      
    end
    Property.purge_records bad_records
    ImportLog.purge_records bad_records
    ImportDiff.purge_records bad_records
    job.update(clean_rows: clean_row_count )
    job.update(total_rows: row_count )

    sorted_rows = rows.sort do |row_1, row_2|
      row_1["event_date"] <=> row_2["event_date"]
    end

    sorted_rows.each_with_index do |row, index|
      puts "\n\tprocessing row: #{index}"
      zi.create_import_log row
    end

    zi.generate_import_diffs job.id    
    zi.generate_properties job.id
    zi.generate_transactions job.id
    temp_file.close!     
  end

  # Checks if this row should even be considered for entry into our database
  #   return false if 
  #     is a retirement community
  #     is a below market, affordable housing type
  #     is an auction type
  #
  def accept_zillow_row(row)
    if row["event_date"].nil?
      puts "\t\tevent_date cannot be nil"
      return false
    elsif row["transaction_type_raw"].present? && row["transaction_type_raw"].downcase.strip == "auction"
      puts "\t\ttransaction_type_raw cannot be auction"
      return false
    elsif row["ccrc"].present? && row["ccrc"].strip.length > 0
      puts "\t\tcannot be retirement community"
      return false
    elsif row["bmr"].present? && row["bmr"].strip.length > 0
      puts "\t\tcannot be affordable housing type"
      return false
    elsif row["event_name"].nil?
      puts "\t\tevent_name cannot be nil"
      SlackFatalErrorWarning.perform_async row["origin_url"]
      return false
    else
      return true
    end
  end
end