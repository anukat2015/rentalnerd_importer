require 'sidekiq/web'

Rails.application.routes.draw do

  # mount RailsAdmin::Engine => '/admin/panel', :as => 'rails_admin'
  mount Sidekiq::Web => '/admin/sidekiq'
  
  post "/webhook",  :to => "webhook#ping"  

  root to: "prediction_results#cap_ratios"
  
  resources :prediction_results do
    collection do
      get 'cap_ratios'
      get 'outliers'
    end    
  end  

  get 'property_details/data', :defaults => { :format => 'json' }

end
