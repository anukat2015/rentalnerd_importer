class AddLuxuryCoefficientToPredictionNeighborhoods < ActiveRecord::Migration
  def change
    add_column :prediction_neighborhoods, :luxury_coefficient, :float
  end
end
