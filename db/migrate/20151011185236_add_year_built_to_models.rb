class AddYearBuiltToModels < ActiveRecord::Migration
  def change
    add_column :properties, :year_built, :integer
    add_column :import_diffs, :year_built, :integer
    add_column :import_logs, :year_built, :integer
  end
end
