class ChangeAddressToStringImportLogs < ActiveRecord::Migration
  def change
    change_column :import_logs, :address, :text
  end
end
