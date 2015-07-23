class RemoveSourceFromRentalDiff < ActiveRecord::Migration
  def change
    add_column    :rental_diffs, :rental_import_job_id, :integer    
    remove_column :rental_diffs, :import_batch
  end
end
