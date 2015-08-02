class PredictionModel < ActiveRecord::Base
  has_many  :prediction_neighborhoods

  def predicted_rent property_id
    property = Property.find property_id
    predicted_rent =  base_rent + 
                      adjusted_sqft(property) * sqft_coefficient + 
                      property.bedrooms * bedroom_coefficient +
                      property.bathrooms * bathroom_coefficient
  end

  def adjusted_sqft property
    property.sqft * neighborhood_coefficient(property)
    
  end

  def neighborhood_coefficient property
    pn = prediction_neighborhoods.where( prediction_neighborhood_name: property.neighborhood ).first
    if pn.nil?
      puts " could not file neighborhood for #{property.id} "
      return 0
    end
    pn.prediction_neighborhood_coefficient
  end  

end