class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.string :address
      t.string :neighborhood
      t.integer :bedrooms
      t.integer :bathrooms
      t.integer :sqft
      t.string :source
      t.string :origin_url

      t.timestamps
    end
  end
end
