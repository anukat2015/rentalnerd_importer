class PropertyTransactionLog < ActiveRecord::Base

  belongs_to :property
  has_one :prediction_result
  has_one :neighborhoods, through: :property

  after_validation :set_days_on_market
  after_validation :set_transaction_status
  after_validation :set_is_latest, on: [:create, :update]
  after_commit :generate_prediction_results, on: [:create, :update]

  TRANSACTION_TYPES = {
    rental: "rental",
    sales: "sales"
  }

  class << self

    # Returns the closest transaction for a property that matches the criteria
    def guess property_id, rented_date = nil , listed_date = nil, transaction_type = AVAILABLE_TRANSACTION_TYPES[:sales]
      match = guess_matching_transaction property_id, rented_date , listed_date, transaction_type
      return match unless match.nil?
      match = get_exact_matching_transaction property_id, rented_date , listed_date, transaction_type
    end

    # Returns the closest transaction for a property that matches the criteria
    def guess_matching_transaction property_id, rented_date = nil , listed_date = nil, transaction_type = AVAILABLE_TRANSACTION_TYPES[:sales]

      # When no dates are provided avoiding wild guesses
      if rented_date.nil? && listed_date.nil?
        nil

      # When both dates are provided leaving no rooms for guessing - get exact matching transaction
      elsif !rented_date.nil? && !listed_date.nil? 
        nil

      # When only the rented_date is provided - 
      elsif !rented_date.nil?
        PropertyTransactionLog.where( property_id: property_id )
          .where(transaction_type: transaction_type)        
          .where(" date_closed is NULL ")
          .where(" date_listed <= ? ", rented_date)
          .order(" date_listed desc ")
          .limit(1)
          .first

      elsif !listed_date.nil?
        PropertyTransactionLog.where( property_id: property_id )
          .where(transaction_type: transaction_type)
          .where(" date_listed is NULL ")
          .where(" date_closed >= ? ", listed_date)
          .order(" date_closed asc ")
          .limit(1)
          .first
      end

    end    

    # Gets exact matching transaction
    def get_exact_matching_transaction property_id, rented_date = nil, listed_date = nil, transaction_type = AVAILABLE_TRANSACTION_TYPES[:sales]

      query = PropertyTransactionLog.where( property_id: property_id )
      query = query.where( transaction_type: transaction_type )
      query = query.where(date_closed: rented_date ) unless rented_date.nil?
      query = query.where(date_listed: listed_date ) unless listed_date.nil?
      query.first

    end

  end


  def set_days_on_market
    if !date_listed.nil? && !date_closed.nil?
      self.days_on_market = (
        date_closed - date_listed
      ).to_i
    end
  end

  def set_transaction_status
    if !date_closed.nil?
      self.transaction_status = "closed"

    else
      self.transaction_status = "open"

    end
  end

  def set_is_latest
    if is_latest_transaction?
      PropertyTransactionLog.where(property_id: property_id, transaction_type: transaction_type).update_all(is_latest: false)      
      self.is_latest = true
    end
  end

  def is_latest_transaction?
    date_to_check = date_closed || date_listed || -1
    greater_transaction = PropertyTransactionLog.where(property_id: property_id)
      .where( transaction_type: transaction_type)
      .where(" date_closed > ? or date_listed > ? ", date_to_check, date_to_check)
      .first    
    return true if greater_transaction.nil?
    return false      
  end

  def get_most_recent_date
    most_recent_date = date_closed || date_listed
    if date_listed.present? && date_closed.present?
      most_recent_date =  [ date_listed, date_closed ].max
    end
    most_recent_date
  end

  def generate_prediction_results
    pns = property.get_active_prediction_neighborhoods

    if pns.size == 0
      SlackPropertyWarning.perform_async property.id
      return
    end

    pns.each do |pn|
      pm = pn.prediction_model

      curr_transaction_type = transaction_type

      if transaction_type == "rental"
        curr_listed_rent = price
        curr_listed_sale = nil

      elsif transaction_type == "sales"
        curr_listed_rent = nil
        curr_listed_sale = price
      end

      if prediction_result.nil? 
        PredictionResult.create!(
          property_id: property.id,
          prediction_model_id: pm.id,
          listed_rent: curr_listed_rent,
          listed_sale: curr_listed_sale,
          transaction_type: curr_transaction_type,
          property_transaction_log_id: self.id
        )

      # When predicted result was already generated
      else
        puts "\t\t\t\t\tUpdate prediction result: #{prediction_result.id}, type: #{transaction_type}"
        prediction_result.listed_rent         = curr_listed_rent
        prediction_result.listed_sale         = curr_listed_sale
        prediction_result.prediction_model_id = pm.id
        prediction_result.transaction_type    = curr_transaction_type
        prediction_result.save!
      end      
    end
  rescue Exception => e 
    binding.pry

  end


end
