class PropertyTransaction < ActiveRecord::Base
  belongs_to :property
  belongs_to :property_transaction_log 

  def get_prediction_models
    property.prediction_models
  end

  def get_prediction_neighborhoods
    property.prediction_neighborhoods
  end    

end
