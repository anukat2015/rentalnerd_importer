class AddIndexToPropertyTransactions < ActiveRecord::Migration
  def change
    change_column :property_transactions, :transaction_type, :string, :limit => 8
    add_index :property_transactions, [:property_id, :transaction_type], :unique => true
  end
end
