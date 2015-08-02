namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :cleanup_properties => :environment do 
    Property.all.each do |pp|
      puts "Processing property #{pp.id}"
      pp.save!
      sleep 1
    end
  end

end