class SlackFatalErrorWarning
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( source )
      payload = {}
      payload[:text] =  "ORIGIN_URL: #{source}\n"

    HTTParty.post( ENV['SLACK_FATAL_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end    