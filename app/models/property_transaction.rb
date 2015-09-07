class PropertyTransaction < ActiveRecord::Base
  belongs_to :property
  belongs_to :property_transaction_log 

  after_commit :generate_prediction_results  

  def generate_prediction_results

    transaction_type == "rental"
    PredictionModel.all.each do |pm|
      pr = PredictionResult.where(
        property_id: property.id,
        prediction_model_id: pm.id,
        transaction_type: transaction_type
      ).first

      
      curr_predicted_rent = pm.predicted_rent(property.id)
      curr_transaction_type = transaction_type

      if transaction_type == "rental"
        curr_listed_rent = property_transaction_log.price
        curr_listed_sale = nil
        curr_error_level = curr_predicted_rent - property_transaction_log.price

      elsif transaction_type == "sales"
        curr_listed_rent = nil
        curr_listed_sale = property_transaction_log.price
        curr_error_level = nil
      end

      if pr.nil?

        pr = PredictionResult.create!(
          property_id: property.id,
          prediction_model_id: pm.id,
          predicted_rent: curr_predicted_rent,
          error_level: curr_error_level,
          listed_rent: curr_listed_rent,
          listed_sale: curr_listed_sale,
          transaction_type: curr_transaction_type

        )
        SlackPublisher.perform_async pr.id

      # When predicted rent is not the same as 
      elsif pr.predicted_rent != curr_predicted_rent
        pr.predicted_rent = curr_predicted_rent
        pr.error_level = curr_predicted_rent - property_transaction_log.price
        pr.listed_rent = curr_listed_rent
        pr.listed_sale = curr_listed_sale
        pr.transaction_type = curr_transaction_type

        pr.save!
        SlackPublisher.perform_async pr.id
      end
    end

  end

end
