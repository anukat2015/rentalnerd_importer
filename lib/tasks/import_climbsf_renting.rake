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
    datasource_url = "http://data.getdata.io/n33_f22b4acef257bfa904d548ef21050ca1eses/csv"

    puts "Processing import_logs"
    job = ImportJob.create!(
      source: "climbsf_renting"
    )
    cri = ClimbsfRentingImporter.new

    CSV.foreach( open(datasource_url), :headers => :first_row ).each do |row|      
      row["source"] = "climbsf_renting"
      row["origin_url"] = row["apartment page"]
      row["import_job_id"] = job.id
      cri.create_import_log row
    end
    puts "\n\n\n"

    cri.generate_import_diffs job.id
    cri.generate_properties job.id
    cri.generate_transactions job.id
  end

end