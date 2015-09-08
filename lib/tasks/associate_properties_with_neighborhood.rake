require 'json'

namespace :db do
  desc "associates each property with a neighborhood"  
  task :associate_properties_with_neighborhoods => :environment do 
    Property.all.each do |pp|
      pp.associate_with_neighborhoods
    end
  end
end