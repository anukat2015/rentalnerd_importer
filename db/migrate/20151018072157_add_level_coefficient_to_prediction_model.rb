class AddLevelCoefficientToPredictionModel < ActiveRecord::Migration
  def change
    add_column :prediction_models, :level_coefficient, :float
  end
end
