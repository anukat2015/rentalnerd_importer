# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_renting_importer'
require './lib/tasks/getdata_downloader'

namespace :db do
  
  desc "imports year built data form Zillow"  
  task :import_zillow_year_built => :environment do 
    datasource_url = "http://data.getdata.io/n117_fd94cb453ba90f2c81315985a631b69eeses/csv"
    temp_file = GetdataDownloader.get_file datasource_url

    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      puts "\nprocessing #{row["origin_url"]}"
      row["origin_url"]
      row["year built"]
      p = Property.where(origin_url: row["origin_url"]).first
      if p.present? 
        if row["year built"].present?
          puts "\tpopulating year built"
          puts "\tProperty: #{p.id}"
          puts "\tYear Built: #{row["year built"]}"
          p.year_built = row["year built"].to_i
          p.save!
        else
          puts "\tcould not populate year built for Property: #{p.id}"
        end

      end
    end    
  end

end