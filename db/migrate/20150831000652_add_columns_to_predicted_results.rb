class AddColumnsToPredictedResults < ActiveRecord::Migration
  def change
    add_column :prediction_results, :transaction_type, :string, default: "rental"
    add_column :prediction_results, :listed_sale, :float
  end
end
