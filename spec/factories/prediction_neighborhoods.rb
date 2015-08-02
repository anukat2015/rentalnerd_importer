FactoryGirl.define do
  factory :prediction_neighborhood, :class => 'PredictionNeighborhood' do
    prediction_model
    prediction_neighborhood_name "East Bay (Walnut Creek)"
    prediction_neighborhood_coefficient 10
  end

end
