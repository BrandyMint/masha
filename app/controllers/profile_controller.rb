class ProfileController < ApplicationController
  before_filter :require_login

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    @user.assign_attributes permited_params

    if @user.save
      redirect_to edit_profile_url, :notice => t(:profile_update)
    else
      render :action => :edit, :error => t(:profile_errors)
    end
  end

  private

  def permited_params
    params.require(:user).permit(:name, :pivotal_person_id, :email)
  end
end
