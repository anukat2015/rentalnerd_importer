class Park < ActiveRecord::Base
  has_many :park_vertices, dependent: :destroy

  class << self
    # Returns the shortest distance to the edge of the nearest park
    def shortest_distance property
      pv0 = ParkVertex.nearest_vertex property
      pvs = pv0.adjacent_vertices
      edge_1 = [pv0, pvs.first]
      edge_2 = [pv0, pvs.second]
      d1 = short_distance_to_edge property, edge_1
      d2 = short_distance_to_edge property, edge_2
      [d1, d2].min
    end

    # Calculates the shortest distance of a property to a line on the map defined by array of 2 park_vertices
    #
    # Params:
    #   property:Property
    #   edge:Array[ ParkVertex, ParkVertex ]
    #    
    def shortest_distance_to_edge property, edge
      p_v1  = distance_between_coord property, edge.first
      p_v2  = distance_between_coord property, edge.second    
      v1_v2 = distance_between_coord edge.first, edge.second

      p_acos = ( p_v1 ** 2 + p_v2 ** 2 - v1_v2 ** 2 ) / ( 2 * p_v1 * p_v2 )
      v1_acos = ( p_v1 ** 2 + v1_v2 ** 2 - p_v2 ** 2 ) / ( 2 * p_v1 * v1_v2 )
      
      angle_p_radian = Math.cos(p_acos) ** -1
      angle_v1_radian = Math.cos(v1_acos) ** -1

      # Shortest distance is the distance between property and V1
      if angle_p_radian > angle_v1_radian
        p_v1

      # Shortest distance is the distance the perpendicular line between V1_v2 and property
      else
        sin_v1 = Math.sin angle_v1_radian
        sin_v1 * p_v1

      end
    end

    # Returns the distance given the 2 sets of coordinates
    def distance_between_coord coord1, coord2
      lat1 = coord1.latitude
      lng1 = coord1.longitude
      lat2 = coord2.latitude
      lng2 = coord2.longitude

      Math.sqrt (
        ( lat1 - lat2 ).abs * ( lat1 - lat2 ).abs + 
        ( lng1 - lng2 ).abs * ( lng1 - lng2 ).abs       
      )
    end    
  end  

  def empty_vertices!
    park_vertices.destroy_all
  end  

  def add_vertex vertex
    return if vertex.park_id == id && 
      vertex.vertex_order.present?

    # Vertice is already associated with the park but does not have an order
    if vertex.park_id == id && 
      !vertex.vertex_order.present?
      vertex.update(vertex_order: park_vertices.size - 1 )

    elsif vertex.park_id != id 
      vertex.update( vertex_order: park_vertices.size )
      park_vertices << vertex
    end
  end

end
