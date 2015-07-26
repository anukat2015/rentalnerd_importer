class AddOldLogIdAndNewLogIdToImportDiffs < ActiveRecord::Migration
  def change
    add_column :import_diffs, :old_log_id, :integer
    add_column :import_diffs, :new_log_id, :integer
  end
end
