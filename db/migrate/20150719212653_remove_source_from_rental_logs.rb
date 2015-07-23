class RemoveSourceFromRentalLogs < ActiveRecord::Migration
  def change
    add_column    :rental_logs, :rental_import_job_id, :integer    
    remove_column :rental_logs, :import_batch
  end
end
