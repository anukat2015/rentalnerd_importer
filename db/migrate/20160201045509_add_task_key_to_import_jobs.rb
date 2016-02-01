class AddTaskKeyToImportJobs < ActiveRecord::Migration
  def change
    add_column :import_jobs, :task_key, :string
  end
end
