class AddActiveToPredictionModels < ActiveRecord::Migration
  def change
    add_column :prediction_models, :active, :boolean
  end
end
