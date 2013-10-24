class MembershipsController < ApplicationController
	before_filter :require_login, :users_available
	inherit_resources
	belongs_to :project

	def index
		@invite = Invite.new

		super
	end

	def create
		@project = parent

		@membership = Membership.new project: @project, user: current_user
		authorize_action_for @membership

    if invite_params[:user_id]
      @invite = Invite.new
      user = User.find invite_params[:user_id]
      @project.memberships.create user: user, role: invite_params[:role]
      render :index and return
    else

      user = User.where(email: invite_params[:email]).first

      if user.present?
        @project.memberships.create user: user, role: invite_params[:role]
      else
        @invite = @project.invites.build invite_params.merge(user: current_user)
        if @invite.save
          flash[:notice] = t('invite_sent', email: @invite.email)
        else
          render :index and return
        end
      end
      redirect_to project_memberships_url(@project)
    end

	end

	def destroy
		@membership = Membership.find params[:id]
		authorize_action_for(@membership)
		@membership.destroy

		redirect_to project_memberships_url(parent)
	end

	def update
		@membership = Membership.find params[:id]
		authorize_action_for(@membership)
		@membership.role = membership_params[:role]
		@membership.save!

		redirect_to project_memberships_url(parent)
	end

	protected

  def users_available
    @users_available_for_project = current_user.available_users.to_a - parent.users
  end

	def membership_params
		params.require(:membership).permit(:role)
	end

	def invite_params
		params.require(:invite).permit(:email, :role, :user_id)
	end
end
