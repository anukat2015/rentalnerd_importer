class DropColumnsForOutdatedModels < ActiveRecord::Migration
  def change
    remove_column :prediction_neighborhoods, :coefficient
    remove_column :prediction_models, :sqft_coefficient
  end
end
