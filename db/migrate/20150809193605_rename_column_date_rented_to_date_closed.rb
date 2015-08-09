class RenameColumnDateRentedToDateClosed < ActiveRecord::Migration
  def change
    rename_column :import_diffs, :date_rented, :date_closed
    rename_column :import_logs, :date_rented, :date_closed
    rename_column :property_transaction_logs, :date_rented, :date_closed
  end
end
