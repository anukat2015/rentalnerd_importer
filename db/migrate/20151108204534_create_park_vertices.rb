class CreateParkVertices < ActiveRecord::Migration
  def change
    create_table :park_vertices do |t|
      t.integer :park_id
      t.integer :vertex_order
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
