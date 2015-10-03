require 'spec_helper'

describe PredictionModel, type: :model do

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

  it "should create a complete model" do
    prediction_model.prediction_neighborhoods.size.should == 1
  end

  it "should return a valid rental_price" do
    ppt = create(:property_transaction_rental)
    rental = prediction_model.predicted_rent ppt.property.id
    rental.nil?.should == false
    
  end
end
