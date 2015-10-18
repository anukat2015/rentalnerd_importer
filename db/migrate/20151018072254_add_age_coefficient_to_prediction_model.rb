class AddAgeCoefficientToPredictionModel < ActiveRecord::Migration
  def change
    add_column :prediction_models, :age_coefficient, :float
  end
end
