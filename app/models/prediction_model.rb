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
    predicted_rent =  base_rent + 
                      adjusted_sqft(property) * sqft_coefficient + 
                      property.bedrooms * bedroom_coefficient +
                      property.bathrooms * bathroom_coefficient
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
    pn.coefficient
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
