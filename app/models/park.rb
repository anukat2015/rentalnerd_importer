class Park < ActiveRecord::Base
  has_many :park_vertices, dependent: :destroy

  def empty_vertices!
    park_vertices.destroy_all
  end  

  def add_vertice vertex
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
