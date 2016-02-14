require 'docusign_rest'

DocusignRest.configure do |config|
  config.username       = ENV['DOCUSIGN_USERNAME']
  config.password       = ENV['DOCUSIGN_PASSWORD']
  config.integrator_key = ENV['DOCUSIGN_INTEGRATOR_KEY']
  config.account_id     = ENV['DOCUSIGN_ACCOUNT_ID']
  config.api_version    = 'v2'

  # To change between demo and www
  config.endpoint       = 'https://demo.docusign.net/restapi'
end