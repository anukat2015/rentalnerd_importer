class CreatePredictionResults < ActiveRecord::Migration
  def change
    create_table :prediction_results do |t|
      t.integer :property_id
      t.integer :prediction_model_id
      t.float :predicted_rent

      t.timestamps
    end
  end
end
