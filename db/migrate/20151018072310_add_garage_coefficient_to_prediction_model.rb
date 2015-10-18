class AddGarageCoefficientToPredictionModel < ActiveRecord::Migration
  def change
    add_column :prediction_models, :garage_coefficient, :float
  end
end
