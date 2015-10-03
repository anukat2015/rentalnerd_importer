require 'rake'

class SlackPublisher
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( prediction_id )
    pr = PredictionResult.find prediction_id
    pp = Property.find pr.property_id

    payload = {}

    if pr.transaction_type == "rental"
      payload[:text] =  "Property Id: #{pp.id},\n" +
                        "Address: #{pp.address},\n" +
                        "Neighborhood: #{pp.neighborhood},\n" + 
                        "Listed Rent: #{pr.listed_rent},\n" + 
                        "Predicted Rent: #{pr.predicted_rent},\n" +  
                        "Error Level: #{pr.error_level},\n" +
                        "URL: #{pp.origin_url}%\n"
        
    elsif pr.transaction_type == "sales"
      payload[:text] =  "Property Id: #{pp.id},\n" +
                        "Address: #{pp.address},\n" +
                        "Neighborhood: #{pp.neighborhood},\n" + 
                        "Listed Sale Price: #{pr.listed_sale},\n" + 
                        "Predicted Rent: #{pr.predicted_rent},\n" + 
                        "CAP rate: #{pr.cap_rate}%,\n" + 
                        "URL: #{pp.origin_url}%\n"

    end
    
    HTTParty.post( ENV['SLACK_PREDICTIONS_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end