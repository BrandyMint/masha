class UsersController < ApplicationController

  def new
    @reg = RegisterForm.new
  end

  def create
    @reg = RegisterForm.new params[:register_form]

    if @reg.save
      redirect_to root_url, :notice => t(:signed_up)
    else
      render :new
    end
  end

end