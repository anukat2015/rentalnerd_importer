class AddTimestampsToImportJobs < ActiveRecord::Migration
  def change
      add_timestamps(:import_jobs)
  end
end
