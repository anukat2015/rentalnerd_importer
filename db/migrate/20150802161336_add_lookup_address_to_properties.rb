class AddLookupAddressToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :lookup_address, :string
  end
end
