class AddListedRentToPredictionResults < ActiveRecord::Migration
  def change
    add_column :prediction_results, :listed_rent, :float
  end
end
