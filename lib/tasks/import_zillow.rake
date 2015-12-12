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

  desc "imports ClimbSF data for those that have already been listed"  
  task :import_zillow_sf => :environment do 
    di = DataImporter.new
    di.import_zillow_sf
  end

  desc "sets the garage"  
  task :import_zillow_garage => :environment do 
    di = DataImporter.new
    di.set_zillow_garage "http://data.getdata.io/n53_70da17e3370067399d5095287282d302eses/csv"
    di.set_zillow_garage "http://data.getdata.io/n46_b5aee320718b31d44407ddde5ed62909eses/csv"
    di.set_zillow_garage "http://data.getdata.io/n86_19de2d95d00239a0c9263ec9252b66bbeses/csv"
  end

  desc "sets the year built"  
  task :import_zillow_year_built => :environment do 
    di = DataImporter.new
    di.set_zillow_year_built "http://data.getdata.io/n53_70da17e3370067399d5095287282d302eses/csv"
    di.set_zillow_year_built "http://data.getdata.io/n46_b5aee320718b31d44407ddde5ed62909eses/csv"
    di.set_zillow_year_built "http://data.getdata.io/n86_19de2d95d00239a0c9263ec9252b66bbeses/csv"    
  end

end