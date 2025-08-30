# Copyright © 2023 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class TelegramAuthCallbackController < ApplicationController
  def self.sign_params(data_params)
    data_check_string = data_params.sort.map { |k, v| [k, v].join('=') }.join("\n")
    secret_key = OpenSSL::Digest::SHA256.new(ApplicationConfig.bot_token).digest
    OpenSSL::HMAC.hexdigest('sha256', secret_key, data_check_string)
  end

  before_action :authorize_webhook!, only: :create

  def confirm
    verifier = Rails.application.message_verifier :telegram
    token = params[:token].to_s
    if token.present?
      data = verifier.verify token, purpose: :login
      unless data.key? :t
        Bugsnag.notify 'invalid auth token'
        redirect_to new_session_url, notice: 'Невалидный токет авторизации, попробуйте еще раз авторизоваться через сайт'
        return
      end
      if Time.zone.at(data.fetch(:t).to_i) < ApplicationConfig.telegram_auth_expiration.seconds.ago
        Bugsnag.notify 'expired auth token'
        redirect_to new_session_url, notice: 'Токен ваторизации устарел, попробуйте еще раз'
        return
      end
      login data.fetch(:tid)
      redirect_after_login
    else
      redirect_to new_session_url, notice: 'Неверный токен авторизации (1), попробуйте еще раз'
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_session_url, notice: 'Неверный токен авторизации (2), попробуйте еще раз'
  end

  def create
    login data_params
    redirect_after_login
  end

  private

  def data_params
    @data_params ||= params
                     .permit(:id, :first_name, :last_name, :username, :photo_url, :auth_date)
                     .to_h
  end

  def authorize_webhook!
    unless signed?
      Rails.logger.error "Not signed telegram callback #{data_params}, #{self.class.sign_params(data_params)}, #{params[:hash]}"
      raise HumanizedError, 'Unauthorized telegram callback'
    end

    return if fresh?

    Rails.logger.error "Expired telegram callback #{auth_date} must be larget then #{expiration_ago}"
    raise HumanizedError, 'Expired telegram callback'
  end

  def signed?
    self.class.sign_params(data_params) == params[:hash].to_s
  end

  def auth_date
    Time.zone.at(params.fetch(:auth_date).to_i)
  end

  def fresh?
    auth_date >= expiration_ago
  end

  def expiration_ago
    @expiration_ago ||= ApplicationConfig.telegram_auth_expiration.seconds.ago
  end

  def redirect_after_login
    redirect_to projects_url
  end
end
