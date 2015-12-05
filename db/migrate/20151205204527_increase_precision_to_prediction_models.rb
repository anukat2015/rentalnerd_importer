class IncreasePrecisionToPredictionModels < ActiveRecord::Migration
  def up
    change_table :prediction_models do |t|
      t.change :base_rent, :decimal, precision: 30, scale: 20
      t.change :bedroom_coefficient, :decimal, precision: 30, scale: 20
      t.change :bathroom_coefficient, :decimal, precision: 30, scale: 20
      t.change :sqft_coefficient, :decimal, precision: 30, scale: 20
      t.change :elevation_coefficient, :decimal, precision: 30, scale: 20
      t.change :dist_to_park_coefficient, :decimal, precision: 30, scale: 20
      t.change :level_coefficient, :decimal, precision: 30, scale: 20
      t.change :age_coefficient, :decimal, precision: 30, scale: 20
      t.change :garage_coefficient, :decimal, precision: 30, scale: 20
      t.change :mser, :decimal, precision: 30, scale: 20
    end
  end
 
  def down
    change_table :prediction_models do |t|
      t.change :base_rent, :float
      t.change :bedroom_coefficient, :float
      t.change :bathroom_coefficient, :float
      t.change :sqft_coefficient, :float
      t.change :elevation_coefficient, :float
      t.change :dist_to_park_coefficient, :float
      t.change :level_coefficient, :float
      t.change :age_coefficient, :float
      t.change :garage_coefficient, :float
      t.change :mser, :float
    end
  end
end
