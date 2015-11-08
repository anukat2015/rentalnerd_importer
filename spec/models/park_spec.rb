require 'spec_helper'

RSpec.describe Park, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end

  describe "#add_vertex" do
    it "updates the vertices count" do
      park = create(:park)
      pv1 = create(:park_vertex, latitude: 1, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 2)
      pv3 = create(:park_vertex, latitude: 2, longitude: 2)
      pv4 = create(:park_vertex, latitude: 2, longitude: 1)
      park.add_vertex pv1
      park.add_vertex pv2
      park.add_vertex pv3
      park.add_vertex pv4
      park.park_vertices.size.should == 4      
    end

  end  

  describe "#distance_between_coord" do
    it "returns the distance between park_vertex and park_vertex" do
      pv1 = create(:park_vertex, latitude: 1, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 2)
      dis = Park.distance_between_coord pv1, pv2
      dis.should == 1
    end

    it "returns the distance between park_vertex and park_vertex" do
      pv1 = create(:park_vertex, latitude: 1, longitude: 1)
      pv2 = create(:park_vertex, latitude: 2, longitude: 2)
      dis = Park.distance_between_coord pv1, pv2
      dis.should == Math.sqrt(2)
    end    

  end

  describe "formula check" do
    it "should be true" do
      opposite = 1 
      hypotenuse = Math.sqrt ( 2 ) 
      result = opposite / hypotenuse
      result.should == 0.7071067811865475 
    end
  end

  describe "#shortest_distance_to_edge" do
    it "returns shortest distance to edge when angle at p is larger than angle at pv1 " do
      p = create(:park_vertex, latitude: 0, longitude: 0)
      pv1 = create(:park_vertex, latitude: 1, longitude: 0)
      pv2 = create(:park_vertex, latitude: 0, longitude: 1)
      dis = Park.shortest_distance_to_edge p, [pv1, pv2]
      dis.should == 0.967554693140535
    end

    it "returns shortest distance to edge when angle at p is lesser than angle at pv1 " do
      p = create(:park_vertex, latitude: 0, longitude: 0)
      pv1 = create(:park_vertex, latitude: 1, longitude: 0)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)
      dis = Park.shortest_distance_to_edge p, [pv1, pv2]
      dis.should == 1
    end

  end
end
