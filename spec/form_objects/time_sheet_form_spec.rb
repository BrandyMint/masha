require 'spec_helper'

describe TimeSheetForm do
  subject { described_class }

  describe "date format" do

    context 'invalid date format 67-dsf-000' do
      let(:form) { described_class.new date_from:"67-dsf-000", date_to:"67-dsf-000" }
      it "should be invalid" do
          expect(form).not_to be_valid
      end
    end

    context 'valid date format 12.12.2014 or 2014.12.16' do
      let(:form) { described_class.new date_from:"12.12.2014", date_to:"2014.12.17" }
      it "should be valid" do
        expect(form).to be_valid
      end
    end

    context 'valid with USA date format(mm.dd.yyyy - 12.17.2014) and US locale' do
      let(:form) { described_class.new date_from:"12.17.2014", date_to:"12.12.2014", locale:"en-US" }
      it "should be valid" do
        expect(form).to be_valid
      end
    end

    context 'invalid with USA date format(mm.dd.yyyy - 12.17.2014) without US locale' do
      let(:form) { described_class.new date_from:"12.17.2014", date_to:"12.12.2014", locale:"ru-RU" }
      it "should be invalid" do
        expect(form).not_to be_valid
      end
    end

  end


end