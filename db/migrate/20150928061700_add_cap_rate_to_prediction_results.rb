class AddCapRateToPredictionResults < ActiveRecord::Migration
  def change
    add_column :prediction_results, :cap_rate, :float
  end
end
