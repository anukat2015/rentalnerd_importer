class CreatePredictionNeighborhoods < ActiveRecord::Migration
  def change
    create_table  :prediction_neighborhoods do |t|
      t.integer   :prediction_model_id
      t.string    :prediction_neighborhood_name
      t.float     :prediction_neighborhood_coefficient
      t.timestamps
    end
  end
end
