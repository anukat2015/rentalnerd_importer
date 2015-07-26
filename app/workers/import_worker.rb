class GroupsFetcher
  include OneEyeMap  
  include Sidekiq::Worker

  sidekiq_options queue: :high

end
