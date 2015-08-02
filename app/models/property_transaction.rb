class PropertyTransaction < ActiveRecord::Base
  belongs_to :property
  belongs_to :property_transaction_log 
end
