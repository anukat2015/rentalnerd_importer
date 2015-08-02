class CreatePredictionModels < ActiveRecord::Migration
  def change
    create_table :prediction_models do |t|
      t.float :base_rent
      t.float :bedroom_coefficient   
      t.float :bathroom_coefficient
      t.float :sqft_coefficient
      t.float :elevation_coefficient
      t.timestamps
    end
  end
end
