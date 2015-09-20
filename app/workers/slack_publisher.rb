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
                        "Error Level: #{pr.error_level}\n"
        
    elsif pr.transaction_type == "sales"
      cap = pr.predicted_rent * 12 / pr.listed_sale
      payload[:text] =  "Property Id: #{pp.id},\n" +
                        "Address: #{pp.address},\n" +
                        "Neighborhood: #{pp.neighborhood},\n" + 
                        "Listed Sale Price: #{pr.listed_sale},\n" + 
                        "Predicted Rent: #{pr.predicted_rent},\n" + 
                        "CAP rate: #{cap}\n"

    end
    
    HTTParty.post( ENV['SLACK_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end