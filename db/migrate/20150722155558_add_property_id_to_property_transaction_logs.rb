class AddPropertyIdToPropertyTransactionLogs < ActiveRecord::Migration
  def change
    add_column :property_transaction_logs, :property_id, :integer
  end
end
