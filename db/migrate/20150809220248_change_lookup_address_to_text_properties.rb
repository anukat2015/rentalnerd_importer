class ChangeLookupAddressToTextProperties < ActiveRecord::Migration
  def change
    change_column :properties, :lookup_address, :text
  end
end
