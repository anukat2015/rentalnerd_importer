# require 'rake'
# Stocker::Application.load_tasks 
# Rake::Task['db:suck_us'].invoke

require 'csv'
require 'open-uri'
require './lib/tasks/rental_creators/climbsf_rented_importer'
require './lib/tasks/getdata_downloader'

namespace :db do
  
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_climbsf_rented => :environment do 
    di = DataImporter.new
    di.import_climbsf_rented
  end

end