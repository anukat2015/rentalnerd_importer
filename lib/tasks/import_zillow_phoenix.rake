# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/import_formatter'
require './lib/tasks/rental_creators/zillow_importer'

namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_zillow_ph => :environment do 
    counter = 0
    datasource_url = "http://data.getdata.io/n53_70da17e3370067399d5095287282d302eses/csv"

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "zillow_ph"
    )

    zi = ZillowImporter.new

    rows = []

    CSV.foreach( open(datasource_url), :headers => :first_row ).each do |row|      
      row["address"] = row["address"].gsub("Incomplete address or missing price?Sometimes listing partners send Zillow listings that do not include a full address or price.To get more details on this property, please contact the listing agent, brokerage, or listing provider.", "")
      row["source"] = "zillow_ph"
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
        zi.create_import_log row
      end
      
    end

    zi.generate_import_diffs job.id    
    zi.generate_properties job.id
    zi.generate_transactions job.id

  end

end