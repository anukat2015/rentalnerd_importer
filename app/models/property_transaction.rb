class PropertyTransaction < ActiveRecord::Base
  belongs_to :property
  belongs_to :property_transaction_log 

  after_commit :generate_prediction_results  

  def generate_prediction_results

    return if transaction_type != "rental"

    PredictionModel.all.each do |pm|
      pr = PredictionResult.where(
        property_id: property.id,
        prediction_model_id: pm.id,
      ).first
      
      curr_predicted_rent = pm.predicted_rent(property.id)      
      
      if pr.nil?

        pr = PredictionResult.create!(
          property_id: property.id,
          prediction_model_id: pm.id,
          predicted_rent: curr_predicted_rent,
          error_level: curr_predicted_rent - property_transaction_log.price,
          listed_rent: property_transaction_log.price
        )
        SlackPublisher.perform_async pr.id

      # When predicted rent is not the same as 
      elsif pr.predicted_rent != predicted_rent
        pr.predicted_rent = curr_predicted_rent
        pr.error_level = curr_predicted_rent - property_transaction_log.price
        pr.listed_rent = property_transaction_log.price
        pr.save!
        SlackPublisher.perform_async pr.id
      end
    end

  end
end
