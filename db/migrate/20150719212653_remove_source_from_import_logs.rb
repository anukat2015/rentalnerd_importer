class RemoveSourceFromImportLogs < ActiveRecord::Migration
  def change
    add_column    :import_logs, :import_job_id, :integer    
    remove_column :import_logs, :import_batch
  end
end
