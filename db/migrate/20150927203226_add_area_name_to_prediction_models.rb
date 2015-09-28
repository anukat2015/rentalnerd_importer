class AddAreaNameToPredictionModels < ActiveRecord::Migration
  def change
    add_column :prediction_models, :area_name, :string
  end
end
