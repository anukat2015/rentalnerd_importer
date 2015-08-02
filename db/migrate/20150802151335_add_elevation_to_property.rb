class AddElevationToProperty < ActiveRecord::Migration
  def change
    add_column :properties, :elevation, :float
  end
end
