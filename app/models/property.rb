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
  after_commit :associate_with_neighborhoods

  has_many :prediction_results, dependent: :destroy
  has_many :property_transaction_logs, dependent: :destroy
  has_many :property_transactions, dependent: :destroy
  has_many :property_neighborhoods, dependent: :destroy
  has_many :neighborhoods, through: :property_neighborhoods
  has_many :prediction_neighborhoods, through: :neighborhoods
  has_many :prediction_models, through: :prediction_neighborhoods

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

  def associate_with_neighborhoods
    possible_nbs = Neighborhood.guess self
    possible_nbs.each do |nb|
      if nb.belongs_here? self
        puts "associating property #{id} with neighborhood #{nb.id}, #{nb.name}"
        PropertyNeighborhood.where(
          property_id: id, 
          neighborhood_id: nb.id 
        ).first_or_create
      end
    end
  end
  
  def get_prediction_neighborhood_for_model prediction_model_id
    prediction_neighborhoods.where( prediction_model_id: prediction_model_id ).first
  end

  def get_active_prediction_neighborhoods
    prediction_neighborhoods.where( active: true )
  end

end
