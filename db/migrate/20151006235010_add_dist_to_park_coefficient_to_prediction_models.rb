class AddDistToParkCoefficientToPredictionModels < ActiveRecord::Migration
  def change
    add_column :prediction_models, :dist_to_park_coefficient, :float
  end
end
