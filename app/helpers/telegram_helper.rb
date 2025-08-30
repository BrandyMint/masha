# frozen_string_literal: true

module TelegramHelper
  def telegram_auth_url
    "https://t.me/#{ApplicationConfig.bot_username}?start=#{auth_session}"
  end

  AUTH_PREFIX = 'auth_'
  def auth_session
    AUTH_PREFIX + cookies.signed[:auth_token] ||= Nanoid.generate
  end
end
