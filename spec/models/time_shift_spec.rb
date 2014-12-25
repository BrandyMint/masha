require 'spec_helper'

describe TimeShift do

  describe "#find TimeSift by bad date format" do

    it do
      expect{ TimeShift.where("date<=?", "15-12-2014".to_date).count }.to_not raise_error
    end

  end

end
