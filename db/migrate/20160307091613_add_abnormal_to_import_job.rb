class AddAbnormalToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :abnormal, :boolean
  end
end
