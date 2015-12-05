# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_renting_importer'
require './lib/tasks/getdata_downloader'

namespace :db do
  
  desc "imports single family data form Zillow"  
  task :import_zillow_single_family => :environment do 
    datasource_url = "http://data.getdata.io/n46_b5aee320718b31d44407ddde5ed62909eses/csv"
    temp_file = GetdataDownloader.get_file datasource_url

    CSV.foreach( open(temp_file), :headers => :first_row ).each do |row|
      puts "\nprocessing #{row["apartment page"]}"
      row["origin_url"]
      row["year built"]
      p = Property.where(origin_url: row["apartment page"]).first
      if p.present? 
        if row["sfh"] == "Single Family"
          puts "\tflagging as single family home"
          puts "\tProperty: #{p.id}"
          p.sfh = true
          p.save!
        else
          puts "\tflagging as normal Property: #{p.id}"
        end

      end
    end    
  end

end