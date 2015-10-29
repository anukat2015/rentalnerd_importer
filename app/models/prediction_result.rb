class PredictionResult < ActiveRecord::Base
  belongs_to :property
  belongs_to :prediction_model
  belongs_to :property_transaction_log
  has_many :neighborhoods, through: :property

  class << self
    def prediction_results_by_cap_ratio(area)
      nids = Neighborhood.where(shapefile_source: area).pluck(:id)
      pids = PropertyNeighborhood.where(neighborhood_id: nids).pluck(:property_id)
      tids = PropertyTransactionLog.where(
        transaction_status: "open", 
        transaction_type: "sales", 
        property_id: pids,
      ).where("price > 30000").pluck(:id)

      where(property_transaction_log_id: tids).order(cap_rate: :desc).includes( :property, :property_transaction_log )
    end    
  end

end
