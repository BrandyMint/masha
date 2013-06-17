class UserController < ApplicationController
  before_filter :require_login

  def edit
    @user = current_user
  end

  def update
    @user = current_user
  end
end
