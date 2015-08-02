class AddColumnErrorLevelToPredictionResults < ActiveRecord::Migration
  def change
    add_column :prediction_results, :error_level, :float
  end
end
