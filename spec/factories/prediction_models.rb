FactoryGirl.define do
  factory :prediction_model, :class => 'PredictionModel' do
    base_rent 777
    bedroom_coefficient 3   
    bathroom_coefficient 4
    sqft_coefficient 5
    elevation_coefficient 6
  end

end
