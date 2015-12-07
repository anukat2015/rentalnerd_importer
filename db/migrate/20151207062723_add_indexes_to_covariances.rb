class AddIndexesToCovariances < ActiveRecord::Migration
  def change
    add_index "covariances", [
      "prediction_model_id",
      "col_type",      
      "col_neighborhood_id", 
      "col_year"
    ], name: "normal_rows", using: :btree
  end
end
