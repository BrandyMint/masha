require 'spec_helper'

describe TimeShift do

  let(:bad_date) { "15-17-2014" }

  let(:date) { "2014-12-15" }



  describe "#find TimeSift by bad date format" do

    it "should conversion error to datetime" do
      expect{ bad_date.to_date }.to raise_error ArgumentError
    end

    it "should convert to datetime" do
      expect{ date.to_date }.not_to raise_error
    end


    it do
      expect{ TimeShift.where("date<=?", bad_date).count }.to raise_error ActiveRecord::StatementInvalid
    end


    it "should return an array of models" do
      expect{ TimeShift.where("date<=?", date).count }.to_not raise_error
    end
  end

end
