class CreateCovariances < ActiveRecord::Migration
  def change
    create_table :covariances do |t|
      t.integer :prediction_model_id
      t.string :row_type
      t.integer :row_neighborhood_id
      t.integer :row_year
      t.boolean :row_is_luxurious
      t.string :col_type
      t.integer :col_neighborhood_id
      t.integer :col_year
      t.boolean :col_is_luxurious
      t.decimal :coefficient, precision: 30, scale: 20
      t.string :row_raw
      t.string :col_raw

      t.timestamps
    end
  end
end
