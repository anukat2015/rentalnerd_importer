class AddTransactionTypeToPropertyTransactionLogs < ActiveRecord::Migration
  def change
    add_column :property_transaction_logs, :transaction_type, :string
  end
end
