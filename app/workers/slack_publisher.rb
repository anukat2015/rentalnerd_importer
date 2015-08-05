require 'rake'

class SlackPublisher
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( prediction_id )
    pr = PredictionResult.find prediction_id
    pp = Property.find pr.property_id
    payload = {
      text: "Property Id: #{pp.id},\n" +
            "Address: #{pp.address},\n" +
            "Neighborhood: #{pp.neighborhood},\n" + 
            "Listed Rent: #{pr.listed_rent},\n" + 
            "Predicted Rent: #{pr.predicted_rent},\n" +  
            "Error Level: #{pr.error_level}\n"
    }
    
    HTTParty.post( ENV['SLACK_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end