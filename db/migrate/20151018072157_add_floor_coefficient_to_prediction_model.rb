class AddFloorCoefficientToPredictionModel < ActiveRecord::Migration
  def change
    add_column :prediction_models, :floor_coefficient, :float
  end
end
