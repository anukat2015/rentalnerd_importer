class PropertiesController < ApplicationController
  def index
  end

  def cap_rated
    @property_predictions = []
    Property.includes(
      :neighborhoods
    ).where(
      "neighborhoods.shapefile_source = 'SF' "
    ).references(:neighborhoods)
    .each do |pp|
      ptl = pp.get_latest_transaction 'sales'
      if ptl.transaction_status == 'open'
        @property_predictions << ptl.prediction_result
      end
    end
    
  end

  def waterfall
    @property_id = params["property_id"] || 6063
    prop = Property.find params["property_id"]
    
    pm = prop.get_active_prediction_model
    p_params =  pm.prediction_waterfall_params prop.id

    rent = pm.predicted_rent(@property_id)
    price = prop.get_latest_transaction_price("sales")
    
    unless price.nil? or price == 0 or rent.nil? or rent == 0
      loan_amt = CashFlow.loan_amt(price, rent, 6.0, 30)
      pmt = CashFlow.payment(6.0, loan_amt, 30)
      taxes = CashFlow.taxes(price)
      insurance = CashFlow.insurance(price)
      piti = CashFlow.piti( price, rent, pmt, taxes)
      cash_yield = CashFlow.cash_yield(price, rent)
    end 

    respond_to do |format|
      format.json {
        render :json => {'waterfall' => [
          {
            'name' => "#{prop.bedrooms} Bedrooms",
            'value' => p_params[:bedrooms].to_f
          },
          {
            'name' => "#{prop.bathrooms} Bathrooms",
            'value' => p_params[:bathrooms].to_f
          },
          {
            'name' =>  "#{prop.sqft.to_i} Sq Ft",
            'value' => p_params[:sqft].to_f
          },
          {
            'name' => "#{prop.level}th Level",
            'value' => p_params[:level].to_f
          },
          {
            'name' => "Built in #{prop.year_built}",
            'value' => p_params[:age].to_f
          },
          {
            'name' => "#{prop.elevation.to_i}m Elevation",
            'value' => p_params[:elevation].to_f
          },
          {
            'name' => prop.neighborhood,
            'value' => p_params[:neighborhood].to_f
          },
          {
            'name' => "#{prop.luxurious ? 'Luxury Bldg' : 'Classic Bldg'}",
            'value' => p_params[:luxurious].to_f
          },
          {
            'name' => "#{prop.dist_to_park.to_i}m from Park",
            'value' => p_params[:dist_to_park].to_f
          },
          {
            'name' => "#{prop.garage ? 'Garage' : 'No Garage'}",
            'value' => p_params[:garage].to_f
          }
      ], 'cash_flow' => 
        {
          'rent' => rent.to_i,
          'price' => price.to_i,
          'loan_amt' => loan_amt.to_i,
          'pmt' => pmt.to_i,
          'taxes' => taxes.to_i,
          'insurance' => insurance.to_i,
          'piti' => piti.to_f,
          'cash_yield' => cash_yield.to_f
        }
      
      }
    }
    end
  end
end