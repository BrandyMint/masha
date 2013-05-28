class SessionsController < ApplicationController
  def create
    self.current_user = Authentificator::Base.authentificate auth_hash

    redirect_to projects_url

  rescue
    redirect_to '/', :notice => 'Проблемы с авторизацией'
  end

  def destroy
    self.current_user = nil
    redirect_to root_url, :notice => "До свидания!"
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
