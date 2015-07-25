# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_renting_importer'

namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_climbsf_renting => :environment do 
    counter = 0
    datasource_url = "http://data.getdata.io/n4_46fae6367035ff1e0e869e80d4fccc71eses/csv"

    puts "Processing rental_logs"
    job = RentalImportJob.create!(
      source: "climbsf_renting"
    )
    cri = ClimbsfRentingImporter.new

    CSV.new( open(datasource_url), :headers => :first_row ).each do |row|
      row["source"] = "climbsf_renting"
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