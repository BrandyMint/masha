require 'spec_helper'

describe TimeShiftsController do

	let!(:time_shift_attrs) { attributes_for :time_shift }
	let!(:project) { create :project }

	context "when not logged in" do
		it "all actions return 401" do
			actions = [:index, :show, :new, :create, :edit, :destroy]

			actions.each do |action|
				get action, { :id => 1 }
				response.code.should == "401"
			end
		end
	end

	context "when logged in" do
		before do
			@user = create :user
			@time_shift = create :time_shift, {:user => @user}
			login_user
		end

		describe "#index" do
			it "should be success" do
				get :index
				response.should be_success
			end
		end

		describe "#show" do
			it "should redirect to time_shifts_url" do
				get :show, :id => @time_shift.id
				response.should redirect_to time_shifts_url
			end
		end

		describe "#new" do
			it "should be success" do
				get :new
				response.should be_success
			end
		end

		describe "#create" do
			context "with valid params" do
				it "should redirect to new_time_shift_url" do
					time_shift_attrs.merge!(:project_id => project.id)
					post :create, :time_shift => time_shift_attrs
					TimeShift.where(time_shift_attrs).first.should be_an_instance_of(TimeShift)
					response.should redirect_to new_time_shift_url
				end
			end

			context "with invalid params" do
				it "should be success" do
					post :create, :time_shift => {}
					response.should be_success
				end
			end
		end

		describe "#edit" do
			it "should render new" do
				get :edit, :id => @time_shift.id
				response.should render_template('edit')
			end
		end

		describe "#destroy" do
			it "should redirect to time_shifts_url" do
				get :destroy, :id => @time_shift.id
				TimeShift.where(:id => @time_shift.id).first.should be_nil
				response.should redirect_to time_shifts_url
			end
		end
	end

end
