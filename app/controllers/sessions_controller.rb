class SessionsController < ApplicationController

  def create
    if auth_hash.present?
      omniauth_create
    else
      password_create
    end
  end

  def destroy
    logout
    redirect_to root_url, :notice => "До свидания!"
  end

  def new
    @session = SessionForm.new params[:session_form]
  end

  protected

  def omniauth_create
    auto_login Authentificator::Base.authentificate auth_hash

    redirect_to projects_url

  rescue StandardError => err
    Airbrake.notify err
    Rails.logger.error err
    redirect_to '/', :notice => 'Проблемы с авторизацией'
  end

  def password_create
    @session = SessionForm.new params[:session_form]

    user = login @session.email, @session.password
    if user
      redirect_to projects_url
    else
      flash.now.alert = "Неправильный email или пароль"
      render :new
    end
  end


  def auth_hash
    request.env['omniauth.auth']
  end
end
