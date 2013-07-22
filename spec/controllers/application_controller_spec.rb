require 'spec_helper'

describe ApplicationController do

	controller do
    def index
      raise ApplicationController::NotLogged
    end
  end

  it "should return 401 if NotLogged raised" do
		get :index
		response.code.should == "401"
	end
end
