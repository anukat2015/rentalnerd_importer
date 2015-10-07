class AddRegularCoefficientToPredictionNeighborhoods < ActiveRecord::Migration
  def change
    add_column :prediction_neighborhoods, :regular_coefficient, :float
  end
end
