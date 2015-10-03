class PredictionNeighborhood < ActiveRecord::Base
  belongs_to :prediction_model
  belongs_to :neighborhood
end
