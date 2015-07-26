require 'sidekiq/testing'
Sidekiq::Testing.fake! unless Rails.env.production? 