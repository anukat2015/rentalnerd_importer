class SlackTransactionWarning
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( property_id, transaction_type )
      pt = Property.find property_id
      payload = {}
      payload[:text] =  "Warning: Property was not associated with any #{transaction_type} logs\n" +
                        "property_id: #{property_id},\n" +
                        "address: #{pt.address},\n" +
                        "URL: #{pt.origin_url}\n"

    HTTParty.post( ENV['SLACK_ALERTS_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end    