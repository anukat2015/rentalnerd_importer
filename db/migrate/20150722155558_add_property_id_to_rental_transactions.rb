class AddPropertyIdToRentalTransactions < ActiveRecord::Migration
  def change
    add_column :rental_transactions, :property_id, :integer
  end
end
