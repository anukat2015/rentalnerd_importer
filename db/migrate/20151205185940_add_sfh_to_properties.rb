class AddSfhToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :sfh, :bool, default: false
  end
end
