class PredictionModel < ActiveRecord::Base
  has_many  :prediction_neighborhoods, dependent: :destroy
  has_many  :prediction_results, dependent: :destroy
  has_many  :neighborhoods, through: :prediction_neighborhoods

  class << self

    def import_model! area_name, model_features_name, model_neighborhood_name, model_covariance_name
      model_coeffi_file = File.new( "./lib/tasks/model_files/#{model_features_name}" )
      neighborhood_coeffi_file = File.new( "./lib/tasks/model_files/#{model_neighborhood_name}" )
      model_covariance_file = File.new( "./lib/tasks/model_files/#{model_covariance_name}" )

      pm = PredictionModel.new(area_name: area_name, active: false)      

      CSV.new( open( model_coeffi_file ), :headers => :first_row ).each do |row|
        case row["Effect"]        
        when "bedrooms"
          pm.bedroom_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        when "bathrooms"
          pm.bathroom_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        when "base_rent"
          pm.base_rent = ImportFormatter.to_decimal row["Coefficient"]

        # Used in the old model
        # when "adj_sqft"
        #   pm.sqft_coefficient = ImportFormatter.to_decimal row["Coefficient"]        

        # Used in the new model
        when "dist_to_park"
          pm.dist_to_park_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        # Used in the new model
        when "elevation"
          pm.elevation_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        # Used in the new model
        when "floor", "level"
          pm.level_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        # Used in the new model
        when "age"
          pm.age_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        # Used in the new model
        when "garage"
          pm.garage_coefficient = ImportFormatter.to_decimal row["Coefficient"]

        when "mean square error of residuals"
          pm.mser = ImportFormatter.to_decimal row["Coefficient"]
        end
      end
      pm.save!
      Covariance.import_covariances! pm.id, model_covariance_file
      PredictionNeighborhood.import_prediction_neighborhoods! pm.id, neighborhood_coeffi_file
      pm.activate!
    end

    def deactivate_area! area_name
      PredictionModel.where(area_name: area_name).each do |pm|
        pm.deactivate!
      end
    end

    def most_recent_deactivated_model area_name
      PredictionModel.where(area_name: area_name, active: false).order(id: :desc).limit(1).first
    end

    def get_active_prediction_model area_name
      PredictionModel.where(area_name: area_name, active: true).limit(1).first
    end

  end

  def predicted_rent property_id
    property = Property.find property_id
    predicted_rent =  base_rent 
    predicted_rent += get_bedroom_component property

    predicted_rent += get_bathroom_component property

    # New model
    predicted_rent += get_regular_component property
    predicted_rent += get_luxury_component property
    predicted_rent += get_elevation_component property
    predicted_rent += get_level_component property

    predicted_rent += get_age_component property
    predicted_rent += get_garage_component property
  
  end

  def get_bedroom_component property
    property.bedrooms * bedroom_coefficient
  end

  def get_bathroom_component property
    property.bathrooms * bathroom_coefficient
  end

  def prediction_waterfall_params property_id
    property = Property.find property_id

    pn = property.get_prediction_neighborhood_for_model id

    avg_rent_per_foot = 1.2
    params = {
      bedrooms: get_bedroom_component( property ),
      bathrooms: get_bathroom_component( property ),
      level: get_level_component( property ),
      elevation: get_elevation_component( property ),
      age: get_age_component( property ),
      sqft: property.sqft * avg_rent_per_foot,
      neighborhood: get_regular_component(property) - (avg_rent_per_foot * property.sqft),
      luxurious: get_luxury_component(property),
      dist_to_park: 0,
      garage: get_garage_component(property)
    }
  end

  def get_regular_component(property)
    pn = property.get_prediction_neighborhood_for_model id
    if pn.nil?
      puts " could not find neighborhood for #{property.id}, #{property.neighborhood} "
      return 0
    end

    if !property.luxurious && pn.regular_coefficient.present?
      return property.sqft * pn.regular_coefficient 
    else
      return 0
    end

  end

  def get_luxury_component(property)
    pn = property.get_prediction_neighborhood_for_model id
    if pn.nil?
      puts " could not find neighborhood for #{property.id}, #{property.neighborhood} "
      return 0
    end

    if property.luxurious && pn.luxury_coefficient.present?
      return property.sqft * pn.luxury_coefficient
    else
      return 0
    end
    
  end  

  def get_elevation_component(property)
    if property.elevation.present? && elevation_coefficient.present?
      property.elevation * elevation_coefficient
    else
      0
    end
  end

  def get_level_component(property)
    if property.level.present? && level_coefficient.present?
      property.level * level_coefficient
    else
      0
    end
  end

  def get_age_component(property)
    if property.year_built.present? && age_coefficient.present?
      ( Time.now.year - property.year_built ) * age_coefficient
    else
      0
    end
  end

  def get_garage_component(property)
    if property.garage && garage_coefficient.present?
      garage_coefficient
    else
      0
    end    
  end

  def activate!
    PredictionModel.deactivate_area! area_name    
    update(active: true)
    prediction_neighborhoods.update_all(active: true)
    refresh_property_predictions
  end

  def deactivate!
    update(active: false)
    prediction_neighborhoods.update_all(active: false)
  end

  def regenerate_predictions_for_corresponding_transaction
    prediction_results.each do |pr|
      pr.property_transaction_log.generate_prediction_results unless pr.property_transaction_log.nil?
    end
  end

  def refresh_property_predictions
    neighborhoods.each do |nb|
      nb.refresh_property_predictions! 
    end
  end  

end
