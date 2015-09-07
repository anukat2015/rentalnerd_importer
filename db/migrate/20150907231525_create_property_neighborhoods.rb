class CreatePropertyNeighborhoods < ActiveRecord::Migration
  def change
    create_table :property_neighborhoods do |t|
      t.integer :property_id, limit: 8, null: false, index: true
      t.integer :neighborhood_id, null: false, index: true
      t.timestamps
    end
    add_index :property_neighborhoods, [:property_id, :neighborhood_id], unique: true    
    add_index :property_neighborhoods, :neighborhood_id
  end
end
