class PropertyNeighborhood < ActiveRecord::Base
  belongs_to :property
  belongs_to :neighborhood
end
