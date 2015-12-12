class AddSfhToImportDiffs < ActiveRecord::Migration
  def change
    add_column :import_diffs, :sfh, :bool, default: false
  end
end
