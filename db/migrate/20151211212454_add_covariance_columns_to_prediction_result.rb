class AddCovarianceColumnsToPredictionResult < ActiveRecord::Migration
  def change
    add_column :prediction_results, :pred_std, :decimal, precision: 30, scale: 20
    add_column :prediction_results, :interval_l, :decimal, precision: 30, scale: 20
    add_column :prediction_results, :interval_u, :decimal, precision: 30, scale: 20
  end
end
