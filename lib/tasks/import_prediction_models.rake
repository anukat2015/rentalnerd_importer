require './lib/tasks/import_formatter'

namespace :db do
  desc "imports Prediction Model for San Francisco those that have already been listed"  
  task :import_prediction_model_sf => :environment do   
    puts "Importing prediction model data - SF"

    features_file = "model_features_sf.csv"
    hood_file = "model_hoods_sf.csv"
    covs_file = "model_covs_sf.csv"
    PredictionModel.import_model! "SF", features_file, hood_file, covs_file

  end

  task :import_prediction_model_ph => :environment do   
    puts "Importing prediction model data - PH"

    features_file = "model_features_ph.csv"
    hood_file = "model_hoods_ph.csv"
    covs_file = "model_covs_ph.csv"
    PredictionModel.import_model! "PH", features_file, hood_file, covs_file

  end  

  task :import_prediction_model_bay_area => :environment do   
    puts "Importing prediction model data - BAY_AREA"

    features_file = "model_features_bay_area.csv"
    hood_file = "model_hoods_bay_area.csv"
    covs_file = "model_covs_bay_area.csv"
    PredictionModel.import_model! "BAY_AREA", features_file, hood_file, covs_file

  end    
end