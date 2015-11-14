class Park < ActiveRecord::Base
  has_many :park_vertices, dependent: :destroy

  class << self

    # Returns the shortest distance to the edge of the nearest park
    def shortest_distance property
      pv0 = ParkVertex.nearest_vertex property, rejected_park_ids

      return nil if pv0.nil?
      pvs = pv0.adjacent_vertices

      if pvs.size == 0
        distance_between_coord property, pv0

      elsif pvs.size == 1
        edge_1 = [pv0, pvs.first]
        d1 = shortest_distance_to_edge property, edge_1

      elsif pvs.size == 2
        edge_1 = [pv0, pvs.first]
        edge_2 = [pv0, pvs.second]
        d1 = shortest_distance_to_edge property, edge_1
        d2 = shortest_distance_to_edge property, edge_2
        [d1, d2].min        
      end


    end

    def rejected_park_ids
      select(:id).where("size < #{RentalNerd::Application.config.minimum_park_size}").pluck(:id)
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

      # when the 3 points form a straight line - taking into account floating point error
      if ( p_v1 + v1_v2 ).round(15) == p_v2.round(15)
        return p_v1
      elsif ( p_v2 + v1_v2 ).round(15) == p_v1.round(15)
        return p_v2
      elsif ( p_v2 + p_v1 ).round(15) == v1_v2.round(15)
        return [p_v2, p_v1].min        
      end

      p_acos = ( p_v1 ** 2 + p_v2 ** 2 - v1_v2 ** 2 ) / ( 2 * p_v1 * p_v2 )
      v1_acos = ( p_v1 ** 2 + v1_v2 ** 2 - p_v2 ** 2 ) / ( 2 * p_v1 * v1_v2 )
      v2_acos = ( p_v2 ** 2 + v1_v2 ** 2 - p_v1 ** 2 ) / ( 2 * p_v2 * v1_v2 )
      
      angle_p_radian = Math.acos(p_acos)
      angle_p_degree = radian_to_degree angle_p_radian
      angle_v1_radian = Math.acos(v1_acos)
      angle_v1_degree = radian_to_degree angle_v1_radian
      angle_v2_radian = Math.acos(v2_acos)
      angle_v2_degree = radian_to_degree angle_v2_radian

      # Shortest distance is the distance between property and V1
      if angle_p_radian > angle_v1_radian
        hypotenuse = p_v1
        angel = degree_to_radian 45.0
        shortest_distance = hypotenuse * Math.cos(angel)        

      # Shortest distance is the distance the perpendicular line between V1_v2 and property
      else
        p_v1

      end
    end

    def radian_to_degree rad
      rad / Math::PI * 180
    end

    def degree_to_radian degree 
      degree / 180 * Math::PI
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
      vertex.update( vertex_order: park_vertices.size, park_id: id )
      park_vertices << vertex
    end
  end

end
