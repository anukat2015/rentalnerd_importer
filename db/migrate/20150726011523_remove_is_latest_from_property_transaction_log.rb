class RemoveIsLatestFromPropertyTransactionLog < ActiveRecord::Migration
  def change
    remove_column :property_transaction_logs, :is_latest
  end
end
