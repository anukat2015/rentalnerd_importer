require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_rented_importer'
require './lib/tasks/getdata_downloader'

class DataImporter

  PHOENIX_REPOSITORIES = [
    # "n53_70da17e3370067399d5095287282d302eses" # All,
    "n240_389befbf885f40a30c72a805733d8597eses", #Zillow - Phoenix Arizon - Optimist Park Sw
    "n244_3feab5f91c1d7cb3451cf8234b63796beses", #Zillow - Phoenix Arizon - Sunburst Farms
    "n241_c9a22b742a72200a176d1ab5cecb2453eses", #Zillow - Phoenix Arizon - Daley Park
    "n248_ac09e92962f40d0764175e6345825538eses", #Zillow - Phoenix Arizon - Maple-Ash
    "n242_5ba339d4b337585e4f43b8d9237b86a5eses", #Zillow - Phoenix Arizon - Pinnacle Peak
    "n245_81cba140cb45fbc79a935ae5717c40aceses", #Zillow - Phoenix Arizon - Mitchell Park West
    "n243_5d5271a0f019c6773630d50f6594b552eses", #Zillow - Phoenix Arizon - Cyprus Southwest
    "n246_b0a5d2402225f9d00a6310f64cfab903eses", #Zillow - Phoenix Arizon - McClintock
    "n247_e79a15c7d559edacfbfbf3729cafaff7eses", #Zillow - Phoenix Arizon - Bell De Mar Crossing
    "n249_3f7c67a8dd7f982fd24068fcaa80ddd3eses", #Zillow - Phoenix Arizon - New Village
    "n253_1a96773d9ea2b2b53340bb51e95ff490eses", #Zillow - Phoenix Arizon - Gililland
    "n256_5afbb9ec409e82b840aeb00a799f4665eses", #Zillow - Phoenix Arizon - Baseline-Hardy
    "n250_1623c619ced0c3e6830ee8284b75fe3deses", #Zillow - Phoenix Arizon - Escalante
    "n254_04c572809d631826f871c8bcd776f4bfeses", #Zillow - Phoenix Arizon - Alta Mira
    "n251_b5f0a67bb5d3f93344620fa6af7512a7eses", #Zillow - Phoenix Arizon - Alegre Community
    "n255_ee94fcc869763b9bc708edffa307ee6deses", #Zillow - Phoenix Arizon - Warner Estates
    "n258_b7197671e6bcc6577ec9bd9a826e8158eses", #Zillow - Phoenix Arizon - Kiwanis Park
    "n252_684afc53d481f51b5a7a4d89cdbecf59eses", #Zillow - Phoenix Arizon - Lindon Park
    "n257_2d3ef1814040c9a3ed2ad4ca0626ec1ceses", #Zillow - Phoenix Arizon - Jen Tilly Terrace
    "n212_8865941e9809aacfc3bf844537acdd99eses", #Zillow - Phoenix Arizon - Desert View
    "n225_e63760af1a713eac0893b8ad10b180d6eses", #Zillow - Phoenix Arizon - North Gateway
    "n213_62f390989907a2862ee961ddfa5cba17eses", #Zillow - Phoenix Arizon - Encanto
    "n215_4778402c61f26d9eab984a487a478203eses", #Zillow - Phoenix Arizon - Deer Valley
    "n214_2e3d4abfa7328e507560a1c10448e91feses", #Zillow - Phoenix Arizon - North Scottsdale
    "n223_a4fc3a13f8f1282dcf942e72b0781b8eeses", #Zillow - Phoenix Arizon - West Central
    "n216_1df2d8a17f73a49d04c89d263a9cf6b3eses", #Zillow - Phoenix Arizon - Laveen
    "n218_fc4100f0a9a79f071af7cac8e3b77c92eses", #Zillow - Phoenix Arizon - Ahwatukee Foothills
    "n220_b167d0283f6babece6de793f8c519e74eses", #Zillow - Phoenix Arizon - Estrella
    "n221_fea5a2363637ccd787f82bf27792e07deses", #Zillow - Phoenix Arizon - South Mountain
    "n217_eb0dd6e04cfa9e200711a53f207a336aeses", #Zillow - Phoenix Arizon - Maryvale
    "n219_ed44f6d316fa0fcdbd285f5f881cf28beses", #Zillow - Phoenix Arizon - South Scottsdale
    "n222_fb3de18d007bd20188247f4d25adfb50eses", #Zillow - Phoenix Arizon - Camelback East
    "n224_3a05350b355a86111705a6c5c0e3484aeses", #Zillow - Phoenix Arizon - Central
    "n226_7c42d5bb4cfac1d6d3d95e2f543e7adfeses", #Zillow - Phoenix Arizon - Paradise Valley
    "n228_b6c293013508d170457d814c0758e95feses", #Zillow - Phoenix Arizon - Central City
    "n234_198d4cbf0339188a3e6255f22441ba19eses", #Zillow - Phoenix Arizon - Rural-Geneva
    "n227_8765d2905d39710346ac66769cfbdc30eses", #Zillow - Phoenix Arizon - Northwest
    "n230_868caecc864187c82975ade359ed0e84eses", #Zillow - Phoenix Arizon - Southwest
    "n233_8cb23bdb170116e3ded8226cf406e606eses", #Zillow - Phoenix Arizon - Riverside
    "n237_727b6877c83e44eff7694a4adbc43848eses", #Zillow - Phoenix Arizon - Mach 8
    "n239_367eef79c35accb6ff562e660386f243eses", #Zillow - Phoenix Arizon - Sunset
    "n229_ba0cae0df919416060bd2b2cb96cad3aeses", #Zillow - Phoenix Arizon - Hughes Acres
    "n231_349a66bcbe5a137d9c82717a3b280c7ceses", #Zillow - Phoenix Arizon - North Mountain
    "n235_de919bf33d33c15ab71f0e4a3230c402eses", #Zillow - Phoenix Arizon - Ntna-College
    "n232_f6a350851110f324e67adb0da72a3512eses", #Zillow - Phoenix Arizon - Southeast
    "n236_84181ed7dc4c53773664ddb567c41e0ceses", #Zillow - Phoenix Arizon - Northeast
    "n238_d8db72849cac07b260d38956ba3d9860eses" #Zillow - Phoenix Arizon - Pepperwood
  ]

  class << self
    def is_phoenix_repository? repository_handle
      PHOENIX_REPOSITORIES.include? repository_handle
    end    
  end

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

  def import_zillow_ph task_key=nil
    source_name = "zillow_ph"

    if task_key.nil?
      source_url = "http://data.getdata.io/n53_70da17e3370067399d5095287282d302eses/csv"
    else
      source_url = "http://data.getdata.io/#{task_key}/csv"      
    end
    import_zillow source_name, source_url, task_key
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

  def import_zillow source_name, source_url, task_key=nil
    counter = 0
    datasource_url = source_url
    temp_file = GetdataDownloader.get_file datasource_url

    puts "Processing import_logs"
    if task_key.nil?
      job = ImportJob.create!(
        source: source_name
      )
    else
      job = ImportJob.create!(
        source: source_name,
        task_key: task_key
      )      
    end

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
      end
      
      row["event_date"]       = ImportFormatter.to_date row["event_date"]      
      
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