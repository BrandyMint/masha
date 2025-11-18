# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :require_login

  helper_method :users_available_for_project

  inherit_resources
  belongs_to :project

  def index
    @invite = Invite.new

    super
  end

  def show
    redirect_to project_memberships_url(@project)
  end

  def create
    @project = parent

    @membership = Membership.new project: @project, user: current_user
    authorize_action_for @membership

    if invite_params[:user_id]
      @invite = Invite.new
      user = User.find invite_params[:user_id]
      @project.memberships.create user: user, role: invite_params[:role]
      render(:index)
    else

      user = find_user invite_params[:email]

      if user.present?
        @project.memberships.create user: user, role: invite_params[:role]
      else
        is = InviteService.new @project, invite_params
        is.make_invite(
          success: -> { flash.now[:success] = (t 'flash.invite_sent', email: is.invite.email) },
          failure: lambda {
            flash.now[:error] = (t 'flash.invite_error', email: is.invite.email
                                 render(:index) and return)
          }
        )

        @invite = is.invite
      end
      redirect_to project_memberships_url(@project)
    end
  end

  def update
    @membership = Membership.find params[:id]
    authorize_action_for(@membership)
    @membership.role = membership_params[:role]
    @membership.save!

    redirect_to project_memberships_url(parent)
  end

  def destroy
    @membership = Membership.find params[:id]
    authorize_action_for(@membership)
    @membership.destroy

    redirect_to project_memberships_url(parent)
  end

  protected

  def find_user(email)
    if /@/=~ email
      User.where(email: email).first
    else
      User.where(nickname: email).first || User.where(name: email).first
    end
  end

  def users_available_for_project
    @users_available_for_project ||= current_user.available_users.to_a - parent.users
  end

  def membership_params
    params.expect(membership: [:role])
  end

  def invite_params
    params.expect(invite: %i[email role user_id]).merge(user: current_user)
  end
end
