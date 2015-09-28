require 'spec_helper'

RSpec.describe PropertyTransaction, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end  

  describe '#get_prediction_models' do
    it 'returns corresponding prediction model that is associated to it via the neighborhood it is in' do
      pt = create(:property)
      nb = create(:neighborhood)
      pn = create(:property_neighborhood, property: pt, neighborhood: nb)
      pm = create(:prediction_model)
      pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
      ptsn = create(:property_transaction, property: pt)

      pms = ptsn.get_prediction_models
      pms.size.should == 1
      pms.first.should == pm
    end

    it 'returns nothing if there are no prediction_models associated with the neighborhood it is in' do
      pt = create(:property)
      nb = create(:neighborhood)
      pn = create(:property_neighborhood, property: pt, neighborhood: nb)
      ptsn = create(:property_transaction, property: pt)

      pms = ptsn.get_prediction_models
      pms.size.should == 0
    end

  end
  
end
