require './lib/tasks/import_formatter'

namespace :db do
  desc "imports Prediction Model for San Francisco those that have already been listed"  
  task :import_prediction_model_sf => :environment do   
    puts "Importing prediction model data"

    # Deactivates all prior prediction models for the area 
    PredictionModel.deactivate_area! "SF"
    pm = PredictionModel.new(area_name: "SF", active: true)

    CSV.new( open("./lib/tasks/model_files/model_features_sf_20150920.csv"), :headers => :first_row ).each do |row|
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

    # For each neighborhood coefficient
    CSV.new( open("./lib/tasks/model_files/model_hoods_sf_20150920.csv"), :headers => :first_row ).each do |row|
      curr_name = row["Neighborhood"].gsub("neighborhood_", "")

      # For each matching neighborhood in our database
      #   for neighborhoods that have multiple areas
      has_matching = false
      Neighborhood.where( "name LIKE ?", "%#{curr_name}%" ).each do |nb|
        has_matching = true
        pn = PredictionNeighborhood.new
        pn.prediction_model_id  = pm.id
        pn.name                 = nb.name
        pn.coefficient          = ImportFormatter.to_float row["Multiplier"]

        if nb.nil?
          binding.pry
        else
          pn.neighborhood_id      = nb.id
        end
        pn.save!
      end

      binding.pry unless has_matching
    end

  end
end