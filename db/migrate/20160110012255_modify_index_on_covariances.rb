class ModifyIndexOnCovariances < ActiveRecord::Migration
  def change
    remove_index "covariances", name: "normal_rows"

    add_index "covariances", [
      "prediction_model_id",
      "row_type",
      "col_type",
      "col_neighborhood_id", 
      "col_year"
    ], name: "normal_rows", using: :btree    
  end
end
