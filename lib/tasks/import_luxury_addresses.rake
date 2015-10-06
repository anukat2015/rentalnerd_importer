namespace :db do
  desc "imports addresses that should be marked as luxurious"  
  task :import_luxurious_addresses => :environment do
    luxurious_file = "luxury_buildings.csv"
    CSV.new( open("./lib/tasks/model_files/#{luxurious_file}")).each do |row|
      puts "processing #{row[0]}"
      LuxuryAddress.where( address: row[0] ).first_or_create!
    end
    LuxuryAddress.set_property_grades
  end
end
