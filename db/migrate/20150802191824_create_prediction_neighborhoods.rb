class CreatePredictionNeighborhoods < ActiveRecord::Migration
  def change
    create_table  :prediction_neighborhoods do |t|
      t.integer   :prediction_model_id
      t.string    :name
      t.float     :coefficient
      t.timestamps
    end
  end
end
