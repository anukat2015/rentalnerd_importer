class CreateNeighborhoods < ActiveRecord::Migration
  def change
    create_table :neighborhoods do |t|
      t.string :name
      t.string :source
      t.float :max_latitude
      t.float :min_latitude
      t.float :max_longitude
      t.float :min_longitude

      t.timestamps
    end
  end
end
