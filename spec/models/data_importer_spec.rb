require 'spec_helper'

RSpec.describe DataImporter, type: :model do
  describe "#is_phoenix_repository?" do 

    it "returns true when repository belongs to Phoenix" do
      DataImporter.is_phoenix_repository?( "n53_70da17e3370067399d5095287282d302eses" ).should == true
    end

    it "returns false when repository does not belong to Phoenix" do
      DataImporter.is_phoenix_repository?( "somehwere" ).should == false
    end

  end
end
