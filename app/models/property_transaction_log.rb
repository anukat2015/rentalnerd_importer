class PropertyTransactionLog < ActiveRecord::Base

  belongs_to :property
  has_one :property_transaction
  has_one :prediction_result

  after_validation :set_days_on_market
  after_validation :set_transaction_status
  after_commit :update_property_transaction
  after_commit :generate_prediction_results

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

  def update_property_transaction
    if is_latest_transaction?
      pt = PropertyTransaction.where(
        property_id: property_id,
        transaction_type: transaction_type
      ).first_or_create

      pt.property_transaction_log_id = self.id
      pt.save!
      
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

    most_recent_date = get_most_recent_date

    if most_recent_date.nil?
      SlackTransactionWarning.perform_async property.id
      return

    elsif most_recent_date < Time.now - 30.days
      return
    end

    pns.each do |pn|
      pm = pn.prediction_model

      pr = PredictionResult.where(
        property_id: property.id,
        prediction_model_id: pm.id,
        transaction_type: transaction_type,
        property_transaction_log_id: self.id
      ).first
      
      curr_predicted_rent = pm.predicted_rent(property.id)
      curr_transaction_type = transaction_type

      if transaction_type == "rental"
        curr_listed_rent = price
        curr_listed_sale = nil
        curr_error_level = curr_predicted_rent - price
        cap_rate         = nil

      elsif transaction_type == "sales"
        curr_listed_rent = nil
        curr_listed_sale = price
        curr_error_level = nil
        cap_rate         = ( curr_predicted_rent * 12 / curr_listed_sale * 100 ).round(2)
      end

      if pr.nil?
        pr = PredictionResult.create!(
          property_id: property.id,
          prediction_model_id: pm.id,
          predicted_rent: curr_predicted_rent,
          error_level: curr_error_level,
          listed_rent: curr_listed_rent,
          listed_sale: curr_listed_sale,
          transaction_type: curr_transaction_type,
          property_transaction_log_id: self.id,
          cap_rate: cap_rate
        )
        SlackPublisher.perform_async pr.id

      # When predicted rent is not the same as 
      elsif pr.predicted_rent != curr_predicted_rent
        pr.predicted_rent = curr_predicted_rent
        pr.error_level = curr_predicted_rent - price
        pr.listed_rent = curr_listed_rent
        pr.listed_sale = curr_listed_sale
        pr.transaction_type = curr_transaction_type
        pr.cap_rate = cap_rate
        pr.error_level = curr_error_level

        pr.save!
        SlackPublisher.perform_async pr.id
      end      
    end

  end


end
