class PredictionResult < ActiveRecord::Base
  belongs_to :property
  belongs_to :prediction_model
  belongs_to :property_transaction_log
  has_many :neighborhoods, through: :property

  after_validation :generate_predicted_rent, on: [:create, :update]
  after_validation :generate_covariance_interval, on: [:create, :update]
  after_validation :generate_cap_rate, on: [:create, :update]

  class << self
    def prediction_results_by_cap_ratio(area)
      pm = PredictionModel.get_active_prediction_model area
      nids = Neighborhood.where(shapefile_source: area).pluck(:id)
      pids = PropertyNeighborhood.where(neighborhood_id: nids).pluck(:property_id)
      tids = PropertyTransactionLog.where(
        transaction_status: "open", 
        transaction_type: "sales",
        is_latest: true,
        property_id: pids
      ).where("price > 30000").where(" date_listed > ?", 12.months.ago ).pluck(:id)

      where(property_transaction_log_id: tids, prediction_model_id: pm.id).order(cap_rate: :desc).includes( :property, :property_transaction_log )
    end

    def outliers(area, transaction_type)
      nids = Neighborhood.where(shapefile_source: area).pluck(:id)
      pids = PropertyNeighborhood.where(neighborhood_id: nids).pluck(:property_id)
      query = where(property_id: pids)
        .where( " property_transaction_log_id IS NOT NULL ")
        .where( created_at: 14.days.ago..Time.now )

      case transaction_type
      when "sales"
        query = query.where( 
          "cap_rate > ?", 
          RentalNerd::Application.config.cap_outliers 
        )
        query.order(created_at: :desc).order(cap_rate: :desc)
      when "rental"
        query = query.where( 
          " abs(error_level) > ?", 
          RentalNerd::Application.config.predicted_rental_diff 
        )
        query.order(created_at: :desc).order(error_level: :desc)
      end
    end

  end

  def generate_predicted_rent
    self.predicted_rent = prediction_model.predicted_rent property.id
  end

  def generate_covariance_interval
    covariance_interval = Covariance.compute_intervals self
    self.pred_std = covariance_interval[:pred_std]
    self.interval_l = covariance_interval[:interval_l]
    self.interval_u = covariance_interval[:interval_u]
  end

  def generate_error_level
    if self.transaction_type == "rental" && self.listed_rent.present?
      self.error_level = self.interval_l - self.listed_rent
    end
  end

  def generate_cap_rate
    if self.transaction_type == "sales" && self.listed_sale.present?
      self.cap_rate = ( self.interval_l * 12 / self.listed_sale * 100 ).round(2)
    end
  end

end
