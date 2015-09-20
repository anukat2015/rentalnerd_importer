class ChangeSourceFromNeighborhoods < ActiveRecord::Migration
  def change
    rename_column :neighborhoods, :source, :shapefile_source
  end
end
