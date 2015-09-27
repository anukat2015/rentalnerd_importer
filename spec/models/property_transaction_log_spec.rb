require 'spec_helper'

RSpec.describe PropertyTransactionLog, type: :model do
  describe '#set_days_on_market' do

    it 'sets days on market properly for transaction within a week' do
      date_listed = Time.now
      date_closed = date_listed

      pt = create(:property_transaction_log_rental)
      pt.date_listed = date_listed
      pt.date_closed = date_closed
      pt.set_days_on_market
      pt.days_on_market.should == 0
    end

    it 'sets days on market properly for transaction within a week' do
      date_listed = Time.now
      date_closed = date_listed + 5.days

      pt = create(:property_transaction_log_rental)
      pt.date_listed = date_listed
      pt.date_closed = date_closed
      pt.set_days_on_market
      pt.days_on_market.should == 5
    end

    it 'sets days on market properly for transaction that took a whole year' do
      date_listed = Time.now
      date_closed = date_listed + 365.days

      pt = create(:property_transaction_log_rental)
      pt.date_listed = date_listed
      pt.date_closed = date_closed
      pt.set_days_on_market
      pt.days_on_market.should == 365
    end    
  end

  describe '#guess' do
    it 'returns transaction if queried as it' do
      ptl = create(:property_transaction_log_rental)      
      found_ptl = PropertyTransactionLog.guess ptl[:property_id], ptl[:rented_date] , ptl[:listed_date], ptl[:transaction_type]
      found_ptl.should == ptl
    end

    it 'returns transaction if queried with open complementary rented_date' do
      ptl = create(:property_transaction_log_rental, date_listed: Time.now - 1.year, date_closed: nil)
      found_ptl = PropertyTransactionLog.guess ptl[:property_id], Time.now, nil, ptl[:transaction_type]
      found_ptl.should == ptl
    end

    it 'returns transaction if queried with open complementary listed_date' do
      ptl = create(:property_transaction_log_rental, date_listed: nil, date_closed: Time.now)
      found_ptl = PropertyTransactionLog.guess ptl[:property_id], nil, Time.now - 1.year, ptl[:transaction_type]
      found_ptl.should == ptl
    end

    it 'does not return any transaction that is totally complete even if date_listed is complementary to the one in the transaction' do
      ptl = create(:property_transaction_log_rental, date_listed: Time.now - 1.year, date_closed: Time.now)
      found_ptl = PropertyTransactionLog.guess ptl[:property_id], nil, Time.now - 6.months, ptl[:transaction_type]
      found_ptl.nil?.should == true
    end    

    it 'does not return any transaction that is totally complete even if date_closed is complementary to the one in the transaction' do
      ptl = create(:property_transaction_log_rental, date_listed: Time.now - 1.year, date_closed: Time.now)
      found_ptl = PropertyTransactionLog.guess ptl[:property_id], Time.now - 6.months, nil, ptl[:transaction_type]
      found_ptl.nil?.should == true
    end        
  end
  
end
