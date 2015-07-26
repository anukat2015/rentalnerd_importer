class RemoveSourceFromImportDiff < ActiveRecord::Migration
  def change
    add_column    :import_diffs, :import_job_id, :integer    
    remove_column :import_diffs, :import_batch
  end
end
