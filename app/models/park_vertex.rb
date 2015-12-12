class ParkVertex < ActiveRecord::Base
  belongs_to :park

  class << self

    # Returns the park vertex closes to this current 
    def nearest_vertex property, excluded_park_ids = []
      to_exclude = ""
      if excluded_park_ids.size > 0
        to_exclude = " WHERE park_id NOT IN (#{excluded_park_ids.join(',')})"
      end

      pv = ParkVertex.find_by_sql(" 
        SELECT
          *,
          SQRT(
            POWER(
              ABS( longitude - #{property.longitude} ),
              2
            ) +
            POWER(
              ABS( latitude - #{property.latitude} ),
              2
            )          
          ) AS distance
        FROM
          park_vertices
        #{to_exclude}
        ORDER BY 
          distance ASC
        LIMIT 1
      ")
      pv.first
    end

  end

  def adjacent_vertices
    return [] if park.nil?
    number_vertices = park.park_vertices.count
    order_before = ( number_vertices + vertex_order - 1 ) % number_vertices
    order_after = ( vertex_order + 1 ) % number_vertices
    ParkVertex.where(park_id: park_id)
      .where(vertex_order: [order_before, order_after])
      .order(vertex_order: :asc)
  end  

end
