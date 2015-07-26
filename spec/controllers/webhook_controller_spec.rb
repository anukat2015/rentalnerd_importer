require 'spec_helper'

describe WebhookController do 
  describe "ping" do
    it "should schedule a import worker task" do
      expect {      
        post :ping, { 
          krake_name: "data source name",
          krake_handle: "data_source_handle",
          event_name: "boomz",
          batch_time: Time.now
        }        
      }.to change(ImportWorker.jobs, :size).by(1)      
    end
  end
end