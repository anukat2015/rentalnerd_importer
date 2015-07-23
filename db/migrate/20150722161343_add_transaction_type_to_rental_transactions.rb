class AddTransactionTypeToRentalTransactions < ActiveRecord::Migration
  def change
    add_column :rental_transactions, :transaction_type, :string
  end
end
