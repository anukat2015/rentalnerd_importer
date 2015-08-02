require './lib/tasks/import_formatter'

namespace :db do
  desc "imports ClimbSF data for those that have already been listed"  
  task :import_prediction_model => :environment do   
    pm = PredictionModel.new

    CSV.new( open("./lib/tasks/model_files/model_features.csv"), :headers => :first_row ).each do |row|
      case row["Effect"]
      when "adj_sqft"
        pm.sqft_coefficient = ImportFormatter.to_float row["Coefficient"]
        
      when "bedrooms"
        pm.bedroom_coefficient = ImportFormatter.to_float row["Coefficient"]

      when "bathrooms"
        pm.bathroom_coefficient = ImportFormatter.to_float row["Coefficient"]

      when "base_rent"
        pm.base_rent = ImportFormatter.to_float row["Coefficient"]
      end
    end
    pm.save!

    CSV.new( open("./lib/tasks/model_files/model_hoods.csv"), :headers => :first_row ).each do |row|
      pn = PredictionNeighborhood.new
      pn.prediction_model_id                  = pm.id
      pn.prediction_neighborhood_name         = row["Neighborhood"].gsub("neighborhood_", "")
      pn.prediction_neighborhood_coefficient  = ImportFormatter.to_float row["Multiplier"]
      pn.save!
    end    

  end
end