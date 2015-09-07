class CreateNeighborhoodVertices < ActiveRecord::Migration
  def change
    create_table :neighborhood_vertices do |t|
      t.integer :neighborhood_id
      t.integer :vertex_order
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
  end
end
