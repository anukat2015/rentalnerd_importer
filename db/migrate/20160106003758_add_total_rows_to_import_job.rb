class AddTotalRowsToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :total_rows, :integer
    add_column :import_jobs, :clean_rows, :integer
    add_column :import_jobs, :added_rows, :integer
    add_column :import_jobs, :modified_rows, :integer
    add_column :import_jobs, :removed_rows, :integer
  end
end
