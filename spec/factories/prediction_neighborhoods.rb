FactoryGirl.define do
  factory :prediction_neighborhood, :class => 'PredictionNeighborhood' do
    neighborhood
    prediction_model
    name "East Bay (Walnut Creek)"
    coefficient 0.926041
    active true
  end

end
