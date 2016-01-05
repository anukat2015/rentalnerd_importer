class AddIsLatestToPropertyTransactionLogs < ActiveRecord::Migration
  def change
    add_column :property_transaction_logs, :is_latest, :boolean, default: false
  end
end
