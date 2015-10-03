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
  task :import_zillow_ph => :environment do 
    di = DataImporter.new
    di.import_zillow_ph
  end

end