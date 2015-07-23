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
    datasource_url = "http://data.getdata.io/n19_485a52895ca152c9f9f74554627048e2eses/csv"

    puts "Processing rental_logs"
    job = RentalImportJob.create!(
      source: "climbsf_rented"
    )
    cri = ClimbsfRentedImporter.new

    CSV.new( open(datasource_url), :headers => :first_row ).each do |row|
      row["source"] = "climbsf_rented"
      row["origin_url"] = row["apartment page"]
      row["rental_import_job_id"] = job.id
      cri.create_rental_log row
    end
    puts "\n\n\n"

    cri.generate_rental_diffs job.id
    cri.generate_properties job.id
    cri.generate_transactions job.id
  end

end