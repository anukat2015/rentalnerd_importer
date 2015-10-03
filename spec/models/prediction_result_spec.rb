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

  it "creates a new prediction for each model when a property transaction is saved" do

    nb = create(:neighborhood)
    pn = create(:property_neighborhood, property: property, neighborhood: nb)

    pm = create(:prediction_model)    
    pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
    ptl = create(:property_transaction_log, transaction_type: "sales", property: property )
    generated_rental_price = pm.predicted_rent property.id
    prediction = PredictionResult.where( prediction_model_id: pm.id, property_id: property.id ).first
    prediction.nil?.should == false
    prediction.predicted_rent.round.should == generated_rental_price.round

  end
end
