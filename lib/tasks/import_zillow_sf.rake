# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/import_formatter'
require './lib/tasks/rental_creators/zillow_importer'
require './lib/tasks/getdata_downloader'

namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_zillow_sf => :environment do 
    counter = 0
    datasource_url = "http://data.getdata.io/n46_b5aee320718b31d44407ddde5ed62909eses/csv"
    temp_file = GetdataDownloader.get_file datasource_url

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "zillow_sf"
    )

    zi = ZillowImporter.new

    rows = []

    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|      
      row["address"] = row["address"].gsub("Incomplete address or missing price?Sometimes listing partners send Zillow listings that do not include a full address or price.To get more details on this property, please contact the listing agent, brokerage, or listing provider.", "")
      row["source"] = "zillow_sf"
      row["origin_url"] = row["apartment page"]
      row["import_job_id"] = job.id
      row["sqft"] = row["size"]

      case row["event_name"]
      when "Listed for rent"
        row["price"]            = row["event_price"] 
        row["date_listed"]      = row["event_date"]
        row["transaction_type"] = "rental"

      when "Price change"
        row["price"]        = row["event_price"]
        row["date_listed"]  = row["event_date"]

      when /sold/i
        puts  row["event_name"]
        row["price"]            = row["event_price"] 
        row["date_closed"]      = row["event_date"]
        row["transaction_type"] = "sales"

      when /sale/i
        puts  row["event_name"]
        row["price"]            = row["event_price"] 
        row["date_listed"]      = row["event_date"]
        row["transaction_type"] = "sales"

      when "Listing removed"
        row["price"]        = row["event_price"] 
        row["date_closed"]  = row["event_date"]
        row["date_listed"]  = row["event_date"]
      end

      row["event_date"]       = ImportFormatter.to_date_short_year row["event_date"]      
      
      unless row["event_date"].nil?
        rows << row
      end
      
    end

    sorted_rows = rows.sort do |row_1, row_2|
      row_1["event_date"] <=> row_2["event_date"]
    end

    sorted_rows.foreach do |row|
      zi.create_import_log row
    end
    
    zi.generate_import_diffs job.id    
    zi.generate_properties job.id
    zi.generate_transactions job.id
    temp_file.close!
  end

end