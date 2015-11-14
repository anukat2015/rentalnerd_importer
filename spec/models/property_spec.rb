require 'spec_helper'

describe Property, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end

  let(:property) { create(:property) }
  describe '#extract_level' do
    it 'returns level when format is APT 345' do
      property.address = "2200 Pacific Ave APT 345, San Francisco, CA 94115"
      property.set_level 
      property.level.should == 3
    end

    it 'returns level when format is #345' do
      property.address = "2200 Pacific Ave #345, San Francisco, CA 94115"
      property.set_level 
      property.level.should == 3
    end    

    it 'returns level when format is APT 34C' do
      property.address = "2200 Pacific Ave APT 34C, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end

    it 'returns level when format is #34C' do
      property.address = "2200 Pacific Ave #34C, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end    

    it 'returns level when format is APT 3456' do
      property.address = "2200 Pacific Ave APT 3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end

    it 'returns level when format is #3456' do
      property.address = "2200 Pacific Ave #3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end    

    it 'returns level when format is APT 3K' do
      property.address = "2200 Pacific Ave APT 3K, San Francisco, CA 94115"
      property.set_level
      property.level.should == 3
    end

    it 'returns level when format is #3K' do
      property.address = "2200 Pacific Ave #3K, San Francisco, CA 94115"
      property.set_level
      property.level.should == 3
    end    

    it 'returns level when format is APT 345K' do
      property.address = "2200 Pacific Ave APT 3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end

    it 'returns level when format is #345K' do
      property.address = "2200 Pacific Ave #3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end    
  end

  describe '#set_dist_to_park' do
    it 'should set dist_to_park when saved' do
      stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location_2.json"), :headers => {})
      park1 = create(:park, size: 1000000)
      pv0 = create(:park_vertex, latitude: 1, longitude: 0)
      pv1 = create(:park_vertex, latitude: 0, longitude: 1)
      pv2 = create(:park_vertex, latitude: 1, longitude: 1)

      park1.add_vertex pv0
      park1.add_vertex pv1
      park1.add_vertex pv2

      property.set_dist_to_park
      property.dist_to_park.should == 0.7071067811865476 
    end
  end

end