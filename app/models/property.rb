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
  after_validation :set_level
  after_validation :set_dist_to_park
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
    puts "\tsetting lookup_address"
    temp_neig = neighborhood
    CONFUSING_TERMS.each do |term|    
      temp_neig = temp_neig.gsub( term, "" ) unless temp_neig.nil?      
    end
    self.lookup_address = "#{address}, #{temp_neig}"    
  end

  def set_elevation
    puts "\tsetting elevation for property #{id}"
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
        puts "\tassociating property #{id} with neighborhood #{nb.id}, #{nb.name}"
        PropertyNeighborhood.where(
          property_id: id, 
          neighborhood_id: nb.id 
        ).first_or_create
      end
    end
  end

  def most_recent_prediction
    prediction_results.where()
  end
  
  def get_prediction_neighborhood_for_model prediction_model_id
    prediction_neighborhoods.where( prediction_model_id: prediction_model_id ).first
  end

  def get_active_prediction_neighborhoods
    prediction_neighborhoods.where( active: true )
  end

  def get_active_prediction_model
    prediction_models.where(active: true).first
  end

  def set_level 
    if address =~ /(APT |#)([0-9]{4})/
      # Take first 2 as level
      self.level = address.scan( /(APT |#)([0-9]{2})/).first.second.to_i

    elsif address =~ /(APT |#)([0-9]{3})[A-Z]/
      # Take first 2 as level
      self.level = address.scan( /(APT |#)([0-9]{2})/).first.second.to_i            

    elsif address =~ /(APT |#)([0-9]{3})/
      # Take first as level
      self.level = address.scan( /(APT |#)([0-9]{1})/).first.second.to_i      

    elsif address =~ /(APT |#)([0-9]{2})[A-Z]/
      # Take first 2 as level
      self.level = address.scan( /(APT |#)([0-9]{2})/).first.second.to_i

    elsif address =~ /(APT |#)([0-9])[A-Z]/
      # Take first as level
      self.level = address.scan( /(APT |#)([0-9])/).first.second.to_i
    end
  end

  def set_dist_to_park
    # Only calculate for property in neighborhoods enabled with parks
    intersects = neighborhoods.map(&:shapefile_source) & RentalNerd::Application.config.dist_to_park_enabled
    
    if intersects.size > 0
      self.dist_to_park = Park.shortest_distance self
    end
  end




end
