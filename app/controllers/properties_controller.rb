class PropertiesController < ApplicationController
  def index
  end

  def cap_rated
    # binding.pry
    @property_predictions = []
    Property.includes(
      :neighborhoods,
      property_transactions: [
        property_transaction_log: [
          :prediction_result
        ]
      ]
    ).where(
      "neighborhoods.shapefile_source = 'SF' "

    ).references(:neighborhoods)
    .where(
      "property_transactions.transaction_type = 'sales' "

    ).references(:property_transactions)
    .each do |pp|
      pt = pp.property_transactions.select {|cpt| cpt.transaction_type == 'sales' }.first
      if pt.property_transaction_log.transaction_status == 'open'
        @property_predictions << pt.property_transaction_log.prediction_result
      end
    end
    
  end
end