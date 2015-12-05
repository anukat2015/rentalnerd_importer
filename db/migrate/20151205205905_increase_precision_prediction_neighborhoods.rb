class IncreasePrecisionPredictionNeighborhoods < ActiveRecord::Migration
  def up
    change_table :prediction_neighborhoods do |t|      
      t.change :luxury_coefficient, :decimal, precision: 30, scale: 20
      t.change :regular_coefficient, :decimal, precision: 30, scale: 20
    end
  end
 
  def down
    change_table :prediction_neighborhoods do |t|
      t.change :luxury_coefficient, :float
      t.change :regular_coefficient, :float
    end
  end
end
