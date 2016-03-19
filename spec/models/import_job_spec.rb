require 'spec_helper'

describe ImportJob, type: :model do
  describe "#set_normalcy!" do
    it "updates abnormal to true if removed_rows > 0 and has no previous import_job" do
      ij = create(:import_job, removed_rows: 10, task_key: 'MICKEY_MOUSE')
      ij.set_normalcy!
      ij.abnormal.should == true
    end

    it "updates abnormal to false if removed_rows == 0 and has no previous import_job" do
      ij = create(:import_job, removed_rows: 0, task_key: 'MICKEY_MOUSE')
      ij.set_normalcy!
      ij.abnormal.should == false
    end

    it "updates abnormal to true if removed_rows above NORMALITY_THRESHOLD compared to total rows of previous import_job" do
      ij_1 = create(:import_job, removed_rows: 0, total_rows: 100, task_key: 'MICKEY_MOUSE')
      ij_2 = create(:import_job, removed_rows: 50, total_rows: 100, task_key: 'MICKEY_MOUSE')
      ij_2.set_normalcy!
      ij_2.abnormal.should == true
    end    

    it "updates abnormal to false if removed_rows below NORMALITY_THRESHOLD compared to total rows of previous import_job" do
      ij_1 = create(:import_job, removed_rows: 0, total_rows: 100, task_key: 'MICKEY_MOUSE')
      ij_2 = create(:import_job, removed_rows: 10, total_rows: 100, task_key: 'MICKEY_MOUSE')
      ij_2.set_normalcy!
      ij_2.abnormal.should == false
    end    
  end  
end