require 'spec_helper'

describe ProjectsController do

  before(:each) do
    @user = create :user
    login_user
  end

  describe "GET 'index'" do
    it "should return success" do
      get :index
      response.should be_success
    end
  end

end