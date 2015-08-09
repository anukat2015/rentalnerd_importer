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

end
