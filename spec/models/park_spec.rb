require 'spec_helper'

RSpec.describe Park, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location_2.json"), :headers => {})
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
    it "should return adjacent when opposite and hypotenuse is provided for right angle triangle" do
      opposite = 1 
      hypotenuse = Math.sqrt ( 2 ) 
      result = opposite / hypotenuse
      result.should == 0.7071067811865475 
    end

    it "should be adjacent when hypotenuse and angel of 45 degree is provided" do
      hypotenuse = 1 
      angel = 45.0 / 180 * Math::PI 
      adjacent = hypotenuse * Math.cos(angel)
      adjacent.should == 0.7071067811865476 
    end    
  end

  describe "#shortest_distance_to_edge" do
    it "returns shortest distance to edge when angle at p is larger than angle at pv1 " do
      p = create(:park_vertex, latitude: 0, longitude: 0)
      pv1 = create(:park_vertex, latitude: 1, longitude: 0)
      pv2 = create(:park_vertex, latitude: 0, longitude: 1)
      dis = Park.shortest_distance_to_edge p, [pv1, pv2]
      dis.should == 0.7071067811865476 

      p_v1 = Math.sqrt( ( dis ** 2 ) * 2 )
      p_v1.should == 1
    end

    it "returns shortest distance to edge when angle at p is lesser than angle at pv1 " do
      p = create(:park_vertex, latitude: 0, longitude: 0)
      pv1 = create(:park_vertex, latitude: 1, longitude: 0)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)
      dis = Park.shortest_distance_to_edge p, [pv1, pv2]
      dis.should == 1
    end

  end

  describe "#shortest_distance" do
    it "returns shortest distance to edge when park is indicated" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)

      park.add_vertex pv0
      park.add_vertex pv1
      park.add_vertex pv2

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 0.7071067811865476 

      p_v1 = Math.sqrt( ( dis ** 2 ) * 2 )
      p_v1.should == 1
    end

    it "returns shortest distance to park with only one point" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      park.add_vertex pv0

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 1
    end    

    it "returns shortest distance to park with only two points" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)

      park.add_vertex pv0
      park.add_vertex pv1

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 0.7071067811865476 

      p_v1 = Math.sqrt( ( dis ** 2 ) * 2 )
      p_v1.should == 1
    end

    it "returns shortest distance to park with three points" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)

      park.add_vertex pv0
      park.add_vertex pv1
      park.add_vertex pv2

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 0.7071067811865476 

      p_v1 = Math.sqrt( ( dis ** 2 ) * 2 )
      p_v1.should == 1
    end

    it "returns shortest distance to park with three points with the edges forming a straight line with the second nearest line further away" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 2, longitude: 0)
      pv2 = create(:park_vertex, latitude: 3, longitude: 0)

      park.add_vertex pv0
      park.add_vertex pv1
      park.add_vertex pv2

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 1
    end

    it "returns shortest distance to park with three points with the edges forming a straight line with the property right on the edges" do
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 2, longitude: 0)
      pv2 = create(:park_vertex, latitude: -1, longitude: 0)

      park.add_vertex pv0
      park.add_vertex pv1
      park.add_vertex pv2

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 1
    end    

    it "returns shortest distance to park with four points" do
      stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location_3.json"), :headers => {})
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)
      pv3 = create(:park_vertex, latitude: 2, longitude: 0)

      park.add_vertex pv0
      park.add_vertex pv1
      park.add_vertex pv2
      park.add_vertex pv3

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == Math.sqrt( 2 ** 2 * 2)
    end

    it "returns shortest distance to park with 2 points aligned with property" do
      stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location_4.json"), :headers => {})
      park = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 2, longitude: 0)

      park.add_vertex pv0
      park.add_vertex pv1

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 2
    end    

    it "returns shortest distance park of minimal allowed size" do
      park1 = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)

      park1.add_vertex pv0
      park1.add_vertex pv1
      park1.add_vertex pv2

      park2 = create(:park, size: 1000)
      pv3 = create(:park_vertex, latitude: 0.5, longitude: 0)
      pv4 = create(:park_vertex, latitude: 0, longitude: 0.5)
      pv5 = create(:park_vertex, latitude: 0.5, longitude: 0.5)      

      park2.add_vertex pv3
      park2.add_vertex pv4
      park2.add_vertex pv5

      property = create(:property)
      dis = Park.shortest_distance property
      dis.should == 0.7071067811865476 

      p_v1 = Math.sqrt( ( dis ** 2 ) * 2 )
      p_v1.should == 1
    end    
  end
end
