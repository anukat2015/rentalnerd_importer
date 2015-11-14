require 'spec_helper'

RSpec.describe ParkVertex, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location_2.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end

  let(:property) { create(:property) } 

  describe "#nearest_vertex" do
    it "returns the nearest vertex given a property" do
      park = create(:park, size: 1000000)
      pv1 = create(:park_vertex, latitude: 1, longitude: 1)
      pv2 = create(:park_vertex, latitude: 2, longitude: 2)
      pv3 = create(:park_vertex, latitude: 3, longitude: 3)
      park.add_vertex pv1
      park.add_vertex pv2

      pv = ParkVertex.nearest_vertex property
      pv.id.should == pv1.id
    end

    it "returns the nearest vertex that is not excluded" do
      pv1 = create(:park_vertex, latitude: 1, longitude: 1, park_id: 1)
      pv2 = create(:park_vertex, latitude: 2, longitude: 2, park_id: 2)
      pv = ParkVertex.nearest_vertex( property, [1] )
      pv.id.should == pv2.id      
    end
  end

  describe "#adjacent_vertices" do
    it "returns adjacent_vertices" do
      park = create(:park, size: 1000000)
      pv1 = create(:park_vertex, latitude: 1, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 2)
      pv3 = create(:park_vertex, latitude: 2, longitude: 2)
      pv4 = create(:park_vertex, latitude: 2, longitude: 1)
      park.add_vertex pv1
      park.add_vertex pv2
      park.add_vertex pv3
      park.add_vertex pv4
      
      pvs = pv1.adjacent_vertices
      pvs.size.should == 2
      pvs.first.id.should == pv2.id
      pvs.second.id.should == pv4.id
    end

  end
end
