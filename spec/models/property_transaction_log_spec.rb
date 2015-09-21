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
  
end
