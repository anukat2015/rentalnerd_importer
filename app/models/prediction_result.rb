class PredictionResult < ActiveRecord::Base
  belongs_to :property
  belongs_to :prediction_model
  belongs_to :property_transaction_log
end
