class OmniauthSessionController < ApplicationController

  def create
    auto_login Authentificator::Base.authentificate auth_hash

    redirect_to projects_url

  rescue StandardError => err
    Airbrake.notify err
    Rails.logger.error err
    redirect_to root_url, :notice => t(:session_problems)
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

end
