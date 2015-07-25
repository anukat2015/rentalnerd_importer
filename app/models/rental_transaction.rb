class RentalTransaction < ActiveRecord::Base
  class << self

    # Returns true if we could not find a transaction record for the property that is greater than date provided
    def is_latest_transaction property_id, date_rented=nil, date_listed=nil, transaction_type = "rental"
      date_to_check = date_rented || date_listed || -1
      greater_transaction = RentalTransaction.where(property_id: property_id)
        .where( transaction_type: transaction_type)
        .where(" date_rented > ? or date_listed > ? ", date_to_check, date_to_check)
        .first

      return true if greater_transaction.nil?
      return false
    end

    # Returns the closest transaction for a property that matches the criteria
    def guess property_id, rented_date = nil , listed_date = nil, transaction_type = "rental"
      match = guess_matching_transaction property_id, rented_date , listed_date, transaction_type
      return match unless match.nil?
      match = get_exact_matching_transaction property_id, rented_date , listed_date, transaction_type
    end

    # Returns the closest transaction for a property that matches the criteria
    def guess_matching_transaction property_id, rented_date = nil , listed_date = nil, transaction_type = "rental"

      # When no dates are provided avoiding wild guesses
      if rented_date.nil? && listed_date.nil?
        nil

      # When both dates are provided leaving no rooms for guessing - get exact matching transaction
      elsif !rented_date.nil? && !listed_date.nil? 
        nil

      # When only the rented_date is provided - 
      elsif !rented_date.nil?
        RentalTransaction.where( property_id: property_id )
          .where(transaction_type: transaction_type)        
          .where(" date_rented is NULL ")
          .where(" date_listed < ? ", rented_date)
          .order(" date_listed desc ")
          .limit(1)
          .first

      elsif !listed_date.nil?
        RentalTransaction.where( property_id: property_id )
          .where(transaction_type: transaction_type)
          .where(" date_listed is NULL ")
          .where(" date_rented > ? ", listed_date)
          .order(" date_rented asc ")
          .limit(1)
          .first
      end

    end    

    # Gets exact matching transaction
    def get_exact_matching_transaction property_id, rented_date = nil, listed_date = nil, transaction_type = "rental"

      query = RentalTransaction.where( property_id: property_id )
      query = query.where( transaction_type: transaction_type )
      query = query.where(date_rented: rented_date ) unless rented_date.nil?
      query = query.where(date_listed: listed_date ) unless listed_date.nil?
      query.first

    end

  end
end
