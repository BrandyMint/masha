require 'spec_helper'

describe SessionsController do

  let!(:user_attrs) { attributes_for :user }

  before do
    @user = create :user
  end

  describe "GET new" do
    it "should return success" do
      get :new
      response.should be_success
    end
  end

  describe "GET create" do
  	context "with valid params" do
	    it "should log in" do
	      get :create, :session_form => { :email => user_attrs[:email], :password => user_attrs[:password] }
	      controller.current_user.should be_an_instance_of(User)
	    end
  	end

    context "with no params" do
      it "should not log in" do
	      get :create
	      controller.current_user.should_not be_an_instance_of(User)
	    end
  	end
  end

  describe "GET destroy" do
    it "should log out" do
      login_user
      get :destroy
      controller.current_user.should_not be_an_instance_of(User)
    end
  end

end