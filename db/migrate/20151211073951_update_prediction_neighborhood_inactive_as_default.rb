class UpdatePredictionNeighborhoodInactiveAsDefault < ActiveRecord::Migration
  def change
    change_column :prediction_neighborhoods, :active, :boolean, default: false
  end
end
