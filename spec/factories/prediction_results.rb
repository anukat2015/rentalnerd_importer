FactoryGirl.define do
  factory :prediction_result, :class => 'PredictionResults' do
    property
    prediction_model
    
    predicted_rent 1.5
  end

end
