require './lib/tasks/import_formatter'

namespace :db do
  desc "imports Prediction Model for San Francisco those that have already been listed"  
  task :import_prediction_model_sf => :environment do   
    puts "Importing prediction model data"

    features_file = "model_features_sf_20151003.csv"
    hood_file = "model_hoods_sf_20151003.csv"

    # Deactivates all prior prediction models for the area 
    PredictionModel.deactivate_area! "SF"
    pm = PredictionModel.new(area_name: "SF", active: true)

    CSV.new( open("./lib/tasks/model_files/#{features_file}"), :headers => :first_row ).each do |row|
      case row["Effect"]        
      when "bedrooms"
        pm.bedroom_coefficient = ImportFormatter.to_float row["Coefficient"]

      when "bathrooms"
        pm.bathroom_coefficient = ImportFormatter.to_float row["Coefficient"]

      when "base_rent"
        pm.base_rent = ImportFormatter.to_float row["Coefficient"]

      # Used in the new model
      when "dist_to_park"
        pm.dist_to_park_coefficient = ImportFormatter.to_float row["Coefficient"]

      # Used in the new model
      when "elevation"
        pm.elevation_coefficient = ImportFormatter.to_float row["Coefficient"]

      # Used in the old model
      when "adj_sqft"
        pm.sqft_coefficient = ImportFormatter.to_float row["Coefficient"]        
      end
    end
    pm.save!

    # For each neighborhood coefficient
    CSV.new( open("./lib/tasks/model_files/#{hood_file}"), :headers => :first_row ).each do |row|
      curr_name = row["neighborhood"]

      # For each matching neighborhood in our database
      #   for neighborhoods that have multiple areas
      has_matching = false
      Neighborhood.where( "name LIKE ?", "%#{curr_name}%" ).each do |nb|
        has_matching = true
        pn = PredictionNeighborhood.new
        pn.prediction_model_id  = pm.id
        pn.name                 = nb.name

        # Old model
        pn.coefficient          = ImportFormatter.to_float row["Multiplier"]

        #New Model
        pn.regular_coefficient  = ImportFormatter.to_float row["regular"]
        pn.luxury_coefficient   = ImportFormatter.to_float row["luxury"]

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