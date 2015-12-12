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

  def waterfall
    @property_id = params["property_id"] || 6063
    prop = Property.find params["property_id"]
    
    pm = prop.get_active_prediction_model
    p_params =  pm.prediction_waterfall_params prop.id

    respond_to do |format|
      format.json {
        render :json => [ 
      {
        'name' => "#{prop.bedrooms} Bedrooms",
        'value' => p_params[:bedrooms]
      },
      {
        'name' => "#{prop.bathrooms} Bathrooms",
        'value' => p_params[:bathrooms]
      },
      {
        'name' =>  "#{prop.sqft} Sq Ft",
        'value' => p_params[:sqft]
      },
      {
        'name' => "#{prop.level}th Level",
        'value' => p_params[:level]
      },
      {
        'name' => "Built in #{prop.year_built}",
        'value' => p_params[:age]
      },
      {
        'name' => "#{prop.elevation}m Elevation",
        'value' => p_params[:elevation]
      },
      {
        'name' => prop.neighborhood,
        'value' => p_params[:neighborhood]
      },
      {
        'name' => "Luxury Bldg #{prop.luxurious}",
        'value' => p_params[:luxurious]
      },
      {
        'name' => "#{prop.dist_to_park}m to Nearest Park",
        'value' => p_params[:dist_to_park]
      },
      {
        'name' => "Has a Garage #{prop.garage}",
        'value' => p_params[:garage]
      }
      ]
    }
    end
  end
end