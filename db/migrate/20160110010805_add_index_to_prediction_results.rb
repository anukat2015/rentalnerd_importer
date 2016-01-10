class AddIndexToPredictionResults < ActiveRecord::Migration
  def change
    add_index "prediction_results", [
      "property_id",
      "transaction_type"
    ], name: "fast_find", using: :btree        
  end
end
