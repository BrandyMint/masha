require 'spec_helper'

describe ProjectsController do

  let!(:project) { create :project }

  context "when not logged in" do
    it "all actions should return 401" do
      actions = [:index, :show]

      actions.each do |action|
        get action, :id => project.id
        response.code.should == "401"
      end
    end
  end

  context "when logged in" do
    before do
      @user = create :user
      login_user
    end

    describe "#index" do
      it "should return success" do
        get :index
        response.should be_success
      end
    end

    describe "#show" do
      it "should redirect to new_time_shift_url" do
        get :show, :id => project.id
        response.should redirect_to new_time_shift_url(:time_shift=>{:project_id=>project.id})
      end
    end
  end

end