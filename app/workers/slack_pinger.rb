require 'rake'

class SlackPinger
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform( import_job_id )
      ij = ImportJob.find import_job_id
      payload = {}
      payload[:text] =  "Import Job started\n" +
                        "ID: #{ij.id},\n" +
                        "Source: #{ij.source},\n"

    HTTParty.post( ENV['SLACK_CHANNEL'], 
      :body => payload.to_json,
      :headers => { 'Content-Type' => 'application/json' } )    
  end
end    