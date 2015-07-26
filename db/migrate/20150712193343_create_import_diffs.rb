class CreateImportDiffs < ActiveRecord::Migration
  def change
    create_table :import_diffs do |t|
      t.string :address      
      t.string :neighborhood      
      t.integer :bedrooms      
      t.integer :bathrooms      
      t.integer :price      
      t.integer :sqft
      t.date :date_rented
      t.date :date_listed
      t.string :source      
      t.string :origin_url
      t.string :diff_type
      t.date :import_batch
      t.timestamps
    end
  end
end
