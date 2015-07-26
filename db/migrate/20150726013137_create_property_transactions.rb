class CreatePropertyTransactions < ActiveRecord::Migration
  def change
    create_table :property_transactions do |t|
      t.integer :property_id
      t.integer :transaction_log_id
      t.string :transaction_type

      t.timestamps
    end
  end
end
