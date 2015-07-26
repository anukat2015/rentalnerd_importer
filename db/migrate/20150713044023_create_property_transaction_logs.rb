class CreatePropertyTransactionLogs < ActiveRecord::Migration
  def change
    create_table :property_transaction_logs do |t|
      t.integer :price
      t.string :transaction_status
      t.date :date_listed
      t.date :date_rented
      t.integer :days_on_market
      t.boolean :is_latest

      t.timestamps
    end
  end
end
