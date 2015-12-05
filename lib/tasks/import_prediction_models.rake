require './lib/tasks/import_formatter'

namespace :db do
  desc "imports Prediction Model for San Francisco those that have already been listed"  
  task :import_prediction_model_sf => :environment do   
    puts "Importing prediction model data - SF"

    features_file = "model_features_sf.csv"
    hood_file = "model_hoods_sf.csv"
    PredictionModel.refresh_model! "SF", features_file, hood_file

  end

  desc "imports Prediction Model for Phoenix those that have already been listed"  
  task :import_prediction_model_ph => :environment do   
    puts "Importing prediction model data - PH"

    features_file = "model_features_ph.csv"
    hood_file = "model_hoods_ph.csv"
    PredictionModel.refresh_model! "PH", features_file, hood_file

  end  

  desc "imports Prediction Model for Bay Area those that have already been listed"  
  task :import_prediction_model_bay_area => :environment do   
    puts "Importing prediction model data - BAY_AREA"

    features_file = "model_features_bay_area.csv"
    hood_file = "model_hoods_bay_area.csv"
    PredictionModel.refresh_model! "BAY_AREA", features_file, hood_file

  end    
end