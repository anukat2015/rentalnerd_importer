require 'spec_helper'

RSpec.describe PropertyTransactionLog, type: :model do

  def google_map_request
    stub_request(:get, /.*maps.googleapis.com.*address.*/).to_return(:status => 200, :body => rni_fixture("google_map_location.json"), :headers => {})
    stub_request(:get, /.*maps.googleapis.com.*elevation.*/).to_return(:status => 200, :body => rni_fixture("google_elevation.json"), :headers => {})
  end

  before do
    google_map_request
  end  
  
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

    describe '#generate_prediction_results' do
      it 'sends a prediction notice to Slack if property is associated with a prediction_neighborhood' do
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", property_id: pt.id )

        SlackPublisher.jobs.clear
        ptl.generate_prediction_results
        SlackPublisher.jobs.size.should == 1
      end

      it 'does not send a prediction notice to Slack if property is not associated with a prediction_neighborhood' do
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", property_id: pt.id )

        SlackPublisher.jobs.clear
        ptl.generate_prediction_results
        SlackPublisher.jobs.size.should == 0
      end

      it 'sends a warning to Slack if property is not associated with any neighborhoods' do
        pt = create(:property)
        nb = create(:neighborhood)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", property_id: pt.id )

        SlackPropertyWarning.jobs.clear
        ptl.generate_prediction_results
        SlackPropertyWarning.jobs.size.should == 1
      end

      it 'does not generate a prediction if corresponding property_transaction_log date_listed is more than 30 days old' do

        transacted_date = Time.now - 1.year
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", date_listed: transacted_date, date_closed: nil , property_id: pt.id )

        SlackPublisher.jobs.clear
        ptl.generate_prediction_results
        SlackPublisher.jobs.size.should == 0
      end

      it 'does not generate a prediction if corresponidng property_transaction_log date_closed is more than 30 days old' do

        transacted_date = Time.now - 1.year
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", date_listed: nil, date_closed: transacted_date, property_id: pt.id )

        SlackPublisher.jobs.clear
        ptl.generate_prediction_results
        SlackPublisher.jobs.size.should == 0
      end

      it 'does not generate a prediction if corresponidng both property_transaction_log date_closed and date_listed are more than 30 days old' do

        transacted_date_1 = Time.now - 2.year
        transacted_date_2 = Time.now - 1.year
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", date_listed: transacted_date_1, date_closed: transacted_date_2, property_id: pt.id )

        SlackPublisher.jobs.clear
        ptl.generate_prediction_results
        SlackPublisher.jobs.size.should == 0
      end      

      it 'generates a prediction_result with cap_rate set if corresponding property_transaction_log transaction_type is sales' do

        transacted_date = Time.now
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", date_listed: transacted_date, date_closed: nil , property_id: pt.id )
        ptl.prediction_result.cap_rate.nil?.should == false
      end

      it 'generates a prediction_result with error_level not set if corresponding property_transaction_log transaction_type is sales' do

        transacted_date = Time.now
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "sales", date_listed: transacted_date, date_closed: nil , property_id: pt.id )
        ptl.prediction_result.error_level.nil?.should == true
      end      

      it 'generates a prediction_result with no cap_rate set if corresponding property_transaction_log transaction_type is rental' do

        transacted_date = Time.now
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "rental", date_listed: transacted_date, date_closed: nil , property_id: pt.id )
        ptl.prediction_result.cap_rate.nil?.should == true
      end      

      it 'generates a prediction_result with error_level set if corresponding property_transaction_log transaction_type is rental' do

        transacted_date = Time.now
        pt = create(:property)
        nb = create(:neighborhood)
        pn = create(:property_neighborhood, property: pt, neighborhood: nb)
        pm = create(:prediction_model)
        pdn = create(:prediction_neighborhood, prediction_model: pm, neighborhood: nb)
        ptl = create(:property_transaction_log, transaction_type: "rental", date_listed: transacted_date, date_closed: nil , property_id: pt.id )
        ptl.prediction_result.error_level.nil?.should == false
      end

    end    
  end

  describe '#is_latest_transaction?'
  
end
