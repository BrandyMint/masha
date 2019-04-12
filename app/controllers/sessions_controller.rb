class SessionsController < ApplicationController
  def create
    @session = SessionForm.new params[:session_form]
    user = login @session.email, @session.password, @session.remember_me

    if user
      redirect_back_or_to time_shifts_url
    else
      gflash :now, error: t('gflash.session_failed')
      render :new
    end
  end

  def destroy
    logout
    redirect_to root_url
  end

  def new
    @session = SessionForm.new params[:session_form]
  end
end
