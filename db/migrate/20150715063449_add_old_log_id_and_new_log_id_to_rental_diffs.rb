class AddOldLogIdAndNewLogIdToRentalDiffs < ActiveRecord::Migration
  def change
    add_column :rental_diffs, :old_log_id, :integer
    add_column :rental_diffs, :new_log_id, :integer
  end
end
