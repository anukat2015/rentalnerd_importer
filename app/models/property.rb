class Property < ActiveRecord::Base
  # attr_accessible :address, :latitude, :longitude
  
  geocoded_by :lookup_address 

  after_validation :cleanup_address
  after_validation :geocode, if: ->(obj){ obj.lookup_address.present? and obj.lookup_address_changed? }
  after_validation :set_elevation, if: ->(obj) { 
    obj.latitude.present? and obj.longitude.present? and (
      obj.elevation.nil? or
      obj.lookup_address_changed?
    )
  }
  after_commit :generate_prediction_results  

  has_many :property_transactions

  CONFUSING_TERMS = [
    "(Inner Mission)",
    "(Van Ness-Civic Center)",
    "(Candlestick Point)",
    "(North Waterfront)",
    "(Pacifica)",
    "East Bay",
    "Peninsula"
  ]

  def cleanup_address
    puts "setting lookup_address"
    temp_neig = neighborhood
    CONFUSING_TERMS.each do |term|    
      temp_neig = temp_neig.gsub( term, "" ) unless temp_neig.nil?      
    end        
    self.lookup_address = "#{address}, #{temp_neig}"    
  end

  def set_elevation
    puts "setting elevation for property #{id}"
    url_string = "https://maps.googleapis.com/maps/api/elevation/json?locations=#{latitude},#{longitude}"
    url = URI.parse URI.encode(url_string)
    api_response = HTTParty.get(url)

    unless api_response["results"].nil? || api_response["results"].size == 0
      result = api_response["results"][0]
      self.elevation = result["elevation"]
    end
  end

  def generate_prediction_results
    PredictionModel.all.each do |pm|
      pr = PredictionResult.where(
        property_id: id,
        prediction_model_id: pm.id,
      ).first

      curr_predicted_rent = pm.predicted_rent(id)      
      
      if pr.nil?
        pr = PredictionResult.create!(
          property_id: id,
          prediction_model_id: pm.id,
          predicted_rent: curr_predicted_rent,
          error_level: curr_predicted_rent - most_recent_rental_price,
          listed_rent: most_recent_rental_price
        )

      # When predicted rent is not the same as 
      elsif pr.predicted_rent != predicted_rent
        pr.predicted_rent = curr_predicted_rent
        pr.error_level = curr_predicted_rent - most_recent_rental_price
        pr.listed_rent = most_recent_rental_price
        pr.save!
      end
    end

  end

  def most_recent_rental_price
    pt = property_transactions.where(transaction_type: "rental").first
    if pt.nil?
      return 0
    else
      return pt.property_transaction_log.price
    end
  end

end
