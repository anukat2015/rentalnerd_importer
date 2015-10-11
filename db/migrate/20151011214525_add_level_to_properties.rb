class AddLevelToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :level, :integer, default: 1
    add_column :import_logs, :level, :integer, default: 1
    add_column :import_diffs, :level, :integer, default: 1
  end
end
