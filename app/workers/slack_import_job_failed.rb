class SlackImportJobFailed
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( respository )
      payload = {}
      payload[:text] =  "IMPORT JOB FAILED: #{respository}\n"

    HTTParty.post( ENV['SLACK_FATAL_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end    