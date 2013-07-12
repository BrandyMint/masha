class SessionsController < ApplicationController

  def create
    @session = SessionForm.new params[:session_form]
    user = login @session.email, @session.password, @session.remember_me
    
    if user
      redirect_to projects_url
    else
      flash.now.alert = t(:session_failed)
      render :new
    end
  end

  def destroy
    logout
    redirect_to root_url, :notice => t(:session_logout)
  end

  def new
    @session = SessionForm.new params[:session_form]
  end
  
end
