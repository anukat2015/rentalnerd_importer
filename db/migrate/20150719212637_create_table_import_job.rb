class CreateTableImportJob < ActiveRecord::Migration
  def change
    create_table :import_jobs do |t|
      t.string :source
    end
  end
end
