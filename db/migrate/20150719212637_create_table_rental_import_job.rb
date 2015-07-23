class CreateTableRentalImportJob < ActiveRecord::Migration
  def change
    create_table :rental_import_jobs do |t|
      t.string :source
    end
  end
end
