class AddPtlIdIndexToPredictionResults < ActiveRecord::Migration
  def change
    add_index "prediction_results", [
      "property_transaction_log_id"
    ], name: "ptl_id", using: :btree    
  end
end
