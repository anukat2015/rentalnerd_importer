class AddTransactionTypeToTables < ActiveRecord::Migration
  def change
    add_column :import_logs, :transaction_type, :string, default: "rental"
    add_column :import_diffs, :transaction_type, :string, default: "rental"
  end
end
