class AddDateTransactedImportDiff < ActiveRecord::Migration
  def change
    add_column :import_diffs, :date_transacted, :date    
  end
end
