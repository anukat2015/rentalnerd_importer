class AddDistToParkToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :dist_to_park, :float
  end
end
