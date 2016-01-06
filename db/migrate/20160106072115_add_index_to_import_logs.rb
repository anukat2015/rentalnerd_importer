class AddIndexToImportLogs < ActiveRecord::Migration
  def change
    add_index "import_logs", [
      "import_job_id",
      "origin_url",
      "source"
    ], name: "fast_find", using: :btree    

    add_index "import_diffs", [
      "import_job_id",
      "origin_url",
      "source"
    ], name: "fast_find", using: :btree        
  end
end
