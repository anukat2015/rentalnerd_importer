class AddNeighborhoodIdToPredictionNeighborhood < ActiveRecord::Migration
  def change
    add_column :prediction_neighborhoods, :neighborhood_id, :integer
  end
end
