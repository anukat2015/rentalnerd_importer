class PropertyTransactionLog < ActiveRecord::Base

  after_validation :set_days_on_market
  after_validation :set_transaction_status
  after_commit :update_property_transaction

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
          .where(" date_rented is NULL ")
          .where(" date_listed < ? ", rented_date)
          .order(" date_listed desc ")
          .limit(1)
          .first

      elsif !listed_date.nil?
        PropertyTransactionLog.where( property_id: property_id )
          .where(transaction_type: transaction_type)
          .where(" date_listed is NULL ")
          .where(" date_rented > ? ", listed_date)
          .order(" date_rented asc ")
          .limit(1)
          .first
      end

    end    

    # Gets exact matching transaction
    def get_exact_matching_transaction property_id, rented_date = nil, listed_date = nil, transaction_type = AVAILABLE_TRANSACTION_TYPES[:sales]

      query = PropertyTransactionLog.where( property_id: property_id )
      query = query.where( transaction_type: transaction_type )
      query = query.where(date_rented: rented_date ) unless rented_date.nil?
      query = query.where(date_listed: listed_date ) unless listed_date.nil?
      query.first

    end

  end


  def set_days_on_market
    if !date_listed.nil? && !date_rented.nil?
      self.days_on_market = (
        date_rented - date_listed
      ).to_i / 1.day
    end    
  end

  def set_transaction_status
    if !date_rented.nil?
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
      pt.transaction_log_id = self.id
      pt.save!
      
    end

  end

  def is_latest_transaction?
    date_to_check = date_rented || date_listed || -1
    greater_transaction = PropertyTransactionLog.where(property_id: property_id)
      .where( transaction_type: transaction_type)
      .where(" date_rented > ? or date_listed > ? ", date_to_check, date_to_check)
      .first    
    return true if greater_transaction.nil?
    return false      
  end

end