class AddDateTransactedImportLogs < ActiveRecord::Migration
  def change
    add_column :import_logs, :date_transacted, :date
  end
end
