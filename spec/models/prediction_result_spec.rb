require 'spec_helper'

RSpec.describe PredictionResult, type: :model do

  let(:property) { create(:property) }
  let(:pn) { create(:prediction_neighborhood) }
  let(:prediction_model) { 
    prediction_model = create(:prediction_model,
      prediction_neighborhoods: [pn]
    )
  }

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end  

  it "creates a new prediction for each model when a new property is created" do
    pptlr = create(:property_transaction_log_rental, property_id: property.id)
    ppt = property.property_transactions.first
    generated_rental_price = prediction_model.predicted_rent property.id
    ppt.save!

    prediction = PredictionResult.where( prediction_model_id: prediction_model.id, property_id: property.id ).first

    prediction.nil?.should == false
    prediction.predicted_rent.round.should == generated_rental_price.round

  end
end
