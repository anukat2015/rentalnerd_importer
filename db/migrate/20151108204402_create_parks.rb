class CreateParks < ActiveRecord::Migration
  def change
    create_table :parks do |t|
      t.string :name
      t.integer :size
      t.string :shapefile_source

      t.timestamps
    end
  end
end
