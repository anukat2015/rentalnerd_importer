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
  after_commit :associate_with_neighborhoods, on: [:create, :update]
  after_commit :reset_prediction_results, on: [:create, :update]

  has_many :prediction_results, dependent: :destroy
  has_many :property_transaction_logs, dependent: :destroy
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

  class << self
    def purge_records origin_urls
      Property.destroy_all( origin_url: origin_urls )
    end

    def most_recent_transaction_date origin_url
      property = Property.where(origin_url: origin_url).first
      if property.present?
        ptl = PropertyTransactionLog.get_most_recent_transaction_log property.id
        if ptl.present?
          ptl.get_most_recent_date
        end
      end
      
    end
  end

  def cleanup_address
    puts "\t\tsetting lookup_address"
    temp_neig = neighborhood
    CONFUSING_TERMS.each do |term|    
      temp_neig = temp_neig.gsub( term, "" ) unless temp_neig.nil?      
    end
    self.lookup_address = "#{address}, #{temp_neig}"    
  end

  def get_latest_transaction transaction_type, is_latest_filter = nil
    query = property_transaction_logs.where(transaction_type: transaction_type)
    if is_latest_filter.present?
      query = query.where(is_latest: true)
    end
    ptl = query.where(transaction_type: transaction_type).order(created_at: :desc).limit(1).first
  end

  def get_latest_transaction_price transaction_type
    ptl = get_latest_transaction transaction_type
    if ptl.present?
      ptl.price
    else
      nil
    end
  end

  def set_elevation
    puts "\t\tsetting elevation for property #{id}"
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
        puts "\t\tassociating property #{id} with neighborhood #{nb.id}, #{nb.name}"
        PropertyNeighborhood.where(
          property_id: id, 
          neighborhood_id: nb.id 
        ).first_or_create
      end
    end
  end

  # sets only the most recent sales and rental transaction logs associated with this property to true
  # sets all other transaction logs associated with this property to false
  def reset_property_transaction_logs
    property_transaction_logs.update_all(is_latest: false)

    ptl_sales = get_latest_transaction "sales"
    ptl_sales.update(is_latest: true) unless ptl_sales.nil?

    ptl_rental = get_latest_transaction "rental"
    ptl_rental.update(is_latest: true) unless ptl_rental.nil?
  end

  def reset_prediction_results
    reset_property_transaction_logs
    property_transaction_logs.where(is_latest: true, transaction_status: "open" ).each do |ptl|
      puts "\t\t\t\tupdate prediction results for property transaction log: #{ptl.id}, type: #{ptl.transaction_type}"
      ptl.generate_prediction_results
    end
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

  def generate_prediction_result
    pns = get_active_prediction_neighborhoods
    generated_results = []
    pns.each do |pn|
      pm = pn.prediction_model
      curr_predicted_rent = pm.predicted_rent id

      pr = PredictionResult.create!(
        property_id: id,
        prediction_model_id: pm.id,
        predicted_rent: curr_predicted_rent
      )
      generated_results << pr
        
    end
    generated_results
  end

end
