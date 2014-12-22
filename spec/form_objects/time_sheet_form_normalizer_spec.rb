require 'spec_helper'

describe TimeSheetFormNormalizer do

  subject { described_class }

  describe "normalization of the date format" do

    context "reverse date" do

      let(:date) { "12-11-2014" }
      let(:normalized_date) { "2014-11-12" }

      let(:result) { described_class.new( {date_from:date} ).perform[:date_from] }

      it "must return reversed date" do
        expect(result).to eq(normalized_date)
      end

    end

    context "leads all delimiters to one" do

      let(:date_one) { "12*11*2014" }
      let(:date_two) { "12/11/2014" }
      let(:normalized_date) { "2014-11-12" }

      let(:result_one) { described_class.new( {date_from:date_one} ).perform[:date_from] }
      let(:result_two) { described_class.new( {date_from:date_two} ).perform[:date_from] }

      it "must return a string with the separator dash" do
        (expect(result_one).to eq(normalized_date)) && (expect(result_two).to eq(normalized_date))
      end

    end

    context "date in the format 'mm.dd.yyyy' and the user locale crazy" do
      let(:date) { "12-17-2014" }
      let(:locale) { ["en-US","en_BZ","fil-PH","ar_SA","iu-Cans-CA"].shuffle.first }
      let(:normalized_date) { "2014-12-17" }

      let(:result) { described_class.new( {date_from:date, locale:locale} ).perform[:date_from] }

      it "change the day and month of places" do
        expect(result).to eq(normalized_date)
      end

    end


  end

end