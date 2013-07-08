class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(permit_params)
    if @user.save
      redirect_to root_url, :notice => "Signed up!"
    else
      render :new
    end
  end

  protected

  def permit_params
    params.require(:user).permit(:name, :email, :password)
  end

end