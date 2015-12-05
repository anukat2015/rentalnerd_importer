class AddMserToPredictionModels < ActiveRecord::Migration
  def change
    add_column :prediction_models, :mser, :float
  end
end
