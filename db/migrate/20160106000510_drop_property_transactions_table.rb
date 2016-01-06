class DropPropertyTransactionsTable < ActiveRecord::Migration
  def change
    drop_table :property_transactions
  end
end
