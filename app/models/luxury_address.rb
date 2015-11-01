class LuxuryAddress < ActiveRecord::Base
  class << self
    def set_property_grades

      LuxuryAddress.all.each do | lxa |
        Property.where( "address LIKE '%#{lxa[:address]}%'" ).update_all(luxurious: true)
      end

    end
  end
end
