class AddIndexToPropertyTransactionLogs < ActiveRecord::Migration
  def change
    add_index "property_transaction_logs", [
      "property_id",
      "transaction_type",
      "is_latest"      
    ], name: "fast_find", using: :btree        
  end
end
