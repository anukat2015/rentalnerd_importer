class ChangeTransactionLogIdToPropertyTransactionLogIdPropertyTransactionTable < ActiveRecord::Migration
  def change
    rename_column :property_transactions, :transaction_log_id, :property_transaction_log_id
  end
end
