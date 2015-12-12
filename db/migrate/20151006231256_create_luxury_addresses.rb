class CreateLuxuryAddresses < ActiveRecord::Migration
  def change
    create_table :luxury_addresses do |t|
      t.string :address

      t.timestamps
    end
  end
end
