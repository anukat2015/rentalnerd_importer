class AddLuxuriousToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :luxurious, :boolean
  end
end
