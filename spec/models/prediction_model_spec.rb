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

  it "sets itself and its prediction_neighborhoods to active = true when deactivated" do
    prediction_model.active.should == true
    pn.active.should == true

    prediction_model.deactivate!

    prediction_model.reload
    prediction_model.active.should == false
    pn.reload
    pn.active.should == false
  end

  it "sets all matching models for area to active = false" do
    pn_1 = create(:prediction_neighborhood)
    prediction_model_1 = create(:prediction_model,
      prediction_neighborhoods: [pn_1],
      area_name: "AREA 51"
    )
    pn_2 = create(:prediction_neighborhood)
    prediction_model_2 = create(:prediction_model,
      prediction_neighborhoods: [pn_2],
      area_name: "AREA 52"
    )    

    PredictionModel.deactivate_area! "AREA 51"

    prediction_model_1.reload
    prediction_model_1.active.should == false
    pn_1.reload
    pn_1.active.should == false

    prediction_model_2.reload
    prediction_model_2.active.should == true
    pn_2.reload
    pn_2.active.should == true
  end

  it "returns the last id of the last prediction model that was deactivated for an area" do
    prediction_model_1 = create(:prediction_model, area_name: "AREA 51" )
    prediction_model_2 = create(:prediction_model, area_name: "AREA 51" )
    PredictionModel.deactivate_area! "AREA 51"

    prediction_model_3 = create(:prediction_model, area_name: "AREA 51" )

    PredictionModel.most_recent_deactivated_model("AREA 51").should == prediction_model_2
  end

  describe '#get_sqft_component' do
    it 'returns value if sqft_coefficient is set' do
      prediction_model.update!( sqft_coefficient: 100)
      pn.update!( coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood])

      result = prediction_model.get_sqft_component property
      result.should == 1000000
    end

    it 'returns 0 if sqft_coefficient is not set' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood])

      result = prediction_model.get_sqft_component property
      result.should == 0
    end

    it 'returns value if prediction_neighborhood.coefficient is set' do
      prediction_model.update!( sqft_coefficient: 100)
      pn.update!( coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood])

      result = prediction_model.get_sqft_component property
      result.should == 1000000      
    end

    it 'returns zero if prediction_neighborhood.coefficient is not set' do
      prediction_model.update!( sqft_coefficient: 100)
      pn.update!( coefficient: nil )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood])

      result = prediction_model.get_sqft_component property
      result.should == 0      
    end    

  end

  describe '#get_regular_component' do

    it 'returns value if prediction_neighborhood.regular_coefficient is set' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, regular_coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: false)

      result = prediction_model.get_regular_component property
      result.should == 10000
    end

    it 'returns zero if prediction_neighborhood.regular_coefficient is set' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, regular_coefficient: nil )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: false)

      result = prediction_model.get_regular_component property
      result.should == 0      
    end

    it 'returns zero if property is not regular' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, regular_coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: false)

      result = prediction_model.get_regular_component property
      result.should == 10000
    end

  end

  describe '#get_luxury_component' do
    it 'returns value if prediction_neighborhood.luxury_coefficient is set' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, luxury_coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: true)

      result = prediction_model.get_luxury_component property
      result.should == 10000
    end

    it 'returns zero if prediction_neighborhood.luxury_coefficient is set' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, luxury_coefficient: nil )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: true)

      result = prediction_model.get_luxury_component property
      result.should == 0      
    end

    it 'returns zero if property is not luxurious' do
      prediction_model.update!( sqft_coefficient: nil)
      pn.update!( coefficient: nil, luxury_coefficient: 100 )
      property = create(:property, sqft: 100, neighborhoods: [pn.neighborhood], luxurious: false)

      result = prediction_model.get_luxury_component property
      result.should == 0
    end    
  end

  describe '#get_elevation_component' do
    it 'returns elevation component if elevation component is set' do
      prediction_model.update!( sqft_coefficient: nil, elevation_coefficient: 100)
      pn.update!( coefficient: nil, luxury_coefficient: 100 )
      property = create(:property, sqft: nil, neighborhoods: [pn.neighborhood], luxurious: false, elevation: 100)

      result = prediction_model.get_elevation_component property
      result.should == 0      
    end
  end

end
