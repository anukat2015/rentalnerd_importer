class PredictionModel < ActiveRecord::Base
  has_many  :prediction_neighborhoods, dependent: :destroy
  has_many  :prediction_results, dependent: :destroy

  class << self
    def deactivate_area! area_name
      PredictionModel.where(area_name: area_name).each do |pm|
        pm.deactivate!
      end
    end

    def most_recent_deactivated_model area_name
      PredictionModel.where(area_name: area_name, active: false).order(id: :desc).limit(1).first
    end    
  end

  def predicted_rent property_id
    property = Property.find property_id
    predicted_rent =  base_rent 
    predicted_rent += get_bedroom_component property

    predicted_rent += get_bathroom_component property


    # Old model
    predicted_rent += get_sqft_component property

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
      neighborhood: get_regular_component(property) + get_sqft_component(property) - (avg_rent_per_foot * property.sqft),
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

  # Uses the old model if the old model is still active
  def get_sqft_component( property )

    if sqft_coefficient.present? 
      return adjusted_sqft(property) * sqft_coefficient
    else
      return 0
    end
    
  end

  def adjusted_sqft property
    property.sqft * neighborhood_coefficient(property)
  end

  # TODO: modify this method to use coefficient of new neighborhoods in the table
  def neighborhood_coefficient property
    pn = property.get_prediction_neighborhood_for_model id
    if pn.nil?
      puts " could not find neighborhood for #{property.id}, #{property.neighborhood} "
      return 0
    end

    # Uses the old model if the old model is still ActiveRecord
    return pn.coefficient unless pn.coefficient.nil?
    return 0
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

end
