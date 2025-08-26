# frozen_string_literal: true

class OmniauthSessionController < ApplicationController
  def create
    auto_login Authentificator.authentificate auth_hash

    redirect_back_or_to just_authorized_redirect_url
  rescue StandardError => e
    Bugsnag.notify e
    Rails.logger.error e
    redirect_back_or_to root_url, gflash: { notice: t('gflash.session_problems') }
  end

  protected

  def just_authorized_redirect_url
    if current_user.available_projects.empty?
      projects_url
    else
      home_url
    end
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
