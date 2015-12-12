class AddActiveToPredictionNeighborhoods < ActiveRecord::Migration
  def change
    add_column :prediction_neighborhoods, :active, :boolean, default: true
  end
end
