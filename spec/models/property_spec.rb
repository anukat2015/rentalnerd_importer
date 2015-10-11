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

    it 'returns level when format is APT 34C' do
      property.address = "2200 Pacific Ave APT 34C, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end

    it 'returns level when format is APT 3456' do
      property.address = "2200 Pacific Ave APT 3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end

    it 'returns level when format is APT 3K' do
      property.address = "2200 Pacific Ave APT 3K, San Francisco, CA 94115"
      property.set_level
      property.level.should == 3
    end

    it 'returns level when format is APT 345K' do
      property.address = "2200 Pacific Ave APT 3456, San Francisco, CA 94115"
      property.set_level
      property.level.should == 34
    end
  end

end