class ChangeAddressToStringProperties < ActiveRecord::Migration
  def change
    change_column :properties, :address, :text
  end
end
