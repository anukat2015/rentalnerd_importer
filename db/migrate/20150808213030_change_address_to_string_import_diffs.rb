class ChangeAddressToStringImportDiffs < ActiveRecord::Migration
  def change
    change_column :import_diffs, :address, :text
  end
end
