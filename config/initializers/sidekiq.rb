Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['KRAKE_REDIS_HOST']}:#{ENV['KRAKE_REDIS_PORT']}/0" }
end
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['KRAKE_REDIS_HOST']}:#{ENV['KRAKE_REDIS_PORT']}/0" }
end