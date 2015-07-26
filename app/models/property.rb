class Property < ActiveRecord::Base
  # attr_accessible :address, :latitude, :longitude
  
  geocoded_by :full_street_address 
  after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }

  def full_street_address 
    "#{address}, #{neighborhood}"
  end
end
