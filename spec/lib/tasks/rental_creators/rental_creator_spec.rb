require 'spec_helper'
require './lib/tasks/rental_creators/rental_creator'

class Includer
  include RentalCreator
end

RSpec.describe RentalCreator do
  let(:ic) { Includer.new }
  let(:pp) { create(:property) }
  let(:default_time) { Time.now }

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    ic.stub(:get_default_date_listed) { default_time }
    google_map_request
  end

  describe '#create_transaction' do
    it 'sets date_listed as current time if both date listed and date closed are not available ' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood)
      ic.create_transaction imd
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.should == default_time.to_date
    end

    it 'does not set date_listed if date list is not available and date closed is available' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.nil?.should == true
      curr_ptl.date_closed.should == default_time.to_date
    end

    it 'does not set date_listed if date list is not available and date closed was already recorded in an existing transaction log' do
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd2
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.nil?.should == true
      curr_ptl.date_closed.should == default_time.to_date
    end

    it 'creates a new transaction log if date_listed is after the date_closed' do
      default_time = 1.year.ago
      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: default_time)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: Time.now)
      ic.create_transaction imd2
      pp.property_transaction_logs.size.should == 2
    end

    it 'appends date_listed to an existing transaction log if date_listed is before the date_closed' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: closed_date)
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1

      imd2 = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date)
      ic.create_transaction imd2
      curr_ptl = pp.property_transaction_logs.first
      curr_ptl.date_listed.should == list_date.to_date
      curr_ptl.date_closed.should == closed_date.to_date
    end

    it 'ignores transactions with the exact closed_date' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_closed: closed_date)
      ic.create_transaction imd
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
    end

    it 'ignores transactions with the exact listed_date' do
      list_date = 1.year.ago
      closed_date = Time.now

      imd = create(:import_diff, address: pp.address, neighborhood: pp.neighborhood, date_listed: list_date)
      ic.create_transaction imd
      ic.create_transaction imd
      pp.property_transaction_logs.size.should == 1
    end

  end
end