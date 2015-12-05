class Neighborhood < ActiveRecord::Base
  has_many :neighborhood_vertices, dependent: :destroy, after_add: :recompute_max_min
  has_many :prediction_neighborhoods, dependent: :destroy
  has_many :property_neighborhoods
  has_many :properties, through: :property_neighborhoods

  # Given a property returns a list of neighborhoods it might potentiall belong to
  def self.guess property
    self.where( " max_latitude >= ? ", property.latitude )
    .where( " min_latitude <= ? ", property.latitude )
    .where( " max_longitude >= ? ", property.longitude )
    .where( " min_longitude <= ? ", property.longitude )
  end

  def refresh_property_predictions!
    properties.each do |pp|
      puts "\t\trefreshing predictions for property: #{pp.id}"
      pp.reset_prediction_results
    end
  end

  def add_vertex vertex
    return if vertex.neighborhood_id == id && 
      vertex.vertex_order.present?

    # Vertice is already associated with the neighborhood but does not have an order
    if vertex.neighborhood_id == id && 
      !vertex.vertex_order.present?
      vertex.update(vertex_order: neighborhood_vertices.size - 1 )

    elsif vertex.neighborhood_id != id 
      vertex.update( vertex_order: neighborhood_vertices.size )
      neighborhood_vertices << vertex
    end
  end

  def is_complete?
    return neighborhood_vertices.size >= 3
  end

  def recompute_max_min vertex
    max_lat = neighborhood_vertices.maximum(:latitude)
    min_lat = neighborhood_vertices.minimum(:latitude)
    max_lng = neighborhood_vertices.maximum(:longitude)
    min_lng = neighborhood_vertices.minimum(:longitude)    
    update(
      max_latitude: max_lat,
      min_latitude: min_lat,
      max_longitude: max_lng,
      min_longitude: min_lng
    )
  end

  # Method returns true if property rest inside a neighborhood
  def belongs_here? property
    edges_to_use = get_all_qualified_edges( property )

    deep_cuts = edges_to_use.select { |edge|

      lat_to_lng = ( edge.end_vertex.longitude - edge.start_vertex.longitude ) /  
        ( edge.end_vertex.latitude - edge.start_vertex.latitude )

      longitude_on_edge = ( property.latitude - edge.start_vertex.latitude ) * lat_to_lng + 
        edge.start_vertex.longitude

      property.longitude < longitude_on_edge

    }
    
    deep_cuts.size % 2 == 1

  end

  # Returns a list of all neighborhood_edges where maximum latitude of each edge 
  # either ends after or starts on the same point of latitude as the property provided
  def get_all_qualified_edges property
    get_all_edges.select { |edge| 
      higher_lng = [edge.start_vertex.latitude, edge.end_vertex.latitude].max
      lower_lng = [edge.start_vertex.latitude, edge.end_vertex.latitude].min
      higher_lng > property.latitude && lower_lng <= property.latitude
    }
  end

  # Returns a list of neighborhood_edges constructed from all the neighborhood_vertices 
  # associated with this neighborhood
  def get_all_edges
    ordered_vertices = neighborhood_vertices.order(vertex_order: :asc)
    edges = []
    ordered_vertices.each_index do |index|
      start_index = index
      end_index   = (index + 1) % ordered_vertices.size 
      ne = NeighborhoodEdge.new(
        start_vertex: ordered_vertices[start_index],
        end_vertex: ordered_vertices[end_index]
      )
      edges << ne
    end
    edges
  end

  def empty_vertices!
    neighborhood_vertices.destroy_all
  end

end
