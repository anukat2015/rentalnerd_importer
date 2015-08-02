class Property < ActiveRecord::Base
  # attr_accessible :address, :latitude, :longitude
  
  geocoded_by :full_street_address 
  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }
  after_validation :set_elevation, if: ->(obj) { 
    obj.latitude.present? and obj.longitude.present? and (
      obj.elevation.nil? or
      obj.address_changed?
    )
  }

  def full_street_address
    "#{address}, #{neighborhood}"
  end

  def set_elevation
    url_string = "https://maps.googleapis.com/maps/api/elevation/json?locations=#{latitude},#{longitude}"
    url = URI.parse URI.encode(url_string)
    api_response = HTTParty.get(url)

    unless api_response["results"].nil? && api_response["results"].size == 0
      self.elevation = api_response["results"][0]["elevation"]
    end
  end

end
