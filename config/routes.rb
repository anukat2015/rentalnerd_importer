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
      get 'waterfall', :defaults => { :format => 'json' }
    end    
  end  

  resources :properties do
    collection do
      get 'waterfall', :defaults => { :format => 'json' }
    end    
  end    

end
