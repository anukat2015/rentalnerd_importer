# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_rented_importer'

namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_climbsf_rented => :environment do 
    counter = 0
    datasource_url = "http://data.getdata.io/n34_d7704e8247e565c7d2bd6705148bd338eses/csv"

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "climbsf_rented"
    )
    cri = ClimbsfRentedImporter.new

    CSV.foreach( open(datasource_url), :headers => :first_row ).each do |row|
      row["source"] = "climbsf_rented"
      row["origin_url"] = row["apartment page"]
      row["date_closed"] = row["date_rented"]
      row["import_job_id"] = job.id
      cri.create_import_log row
    end
    puts "\n\n\n"

    cri.generate_import_diffs job.id
    cri.generate_properties job.id
    cri.generate_transactions job.id
  end

end