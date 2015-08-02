FactoryGirl.define do
  factory :prediction_model, :class => 'PredictionModel' do
    base_rent 777.4949582539
    bedroom_coefficient 163.981555
    bathroom_coefficient 222.826018
    sqft_coefficient 2.004296
    elevation_coefficient 6
  end

end
