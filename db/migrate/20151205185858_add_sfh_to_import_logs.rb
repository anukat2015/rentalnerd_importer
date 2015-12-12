class AddSfhToImportLogs < ActiveRecord::Migration
  def change
    add_column :import_logs, :sfh, :bool, default: false
  end
end
