require 'spec_helper'

RSpec.describe PropertyTransactionLog, type: :model do
  describe '#set_days_on_market' do
    it 'sets days on market properly for transaction within a week' do
      pt = create(:property_transaction_log_rental)
      pt.date_listed = 5.days.ago
      pt.date_closed = Time.now
      pt.set_days_on_market
      pt.days_on_market.should == 5
    end

    it 'sets days on market properly for transaction that took a whole year' do
      pt = create(:property_transaction_log_rental)
      pt.date_listed = 1.year.ago
      pt.date_closed = Time.now
      pt.set_days_on_market
      pt.days_on_market.should == 365
    end    
  end
  
end
