class AddPropertyTransactionLogIdToPredictionResult < ActiveRecord::Migration
  def change
    add_column :prediction_results, :property_transaction_log_id, :integer
  end
end
