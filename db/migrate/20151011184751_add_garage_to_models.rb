class AddGarageToModels < ActiveRecord::Migration
  def change
    add_column :properties, :garage, :boolean
    add_column :import_diffs, :garage, :boolean
    add_column :import_logs, :garage, :boolean
  end
end
