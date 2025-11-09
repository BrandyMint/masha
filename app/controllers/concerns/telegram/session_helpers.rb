# frozen_string_literal: true

# Хелперы для работы с TelegramSession
module Telegram
  module SessionHelpers
    extend ActiveSupport::Concern

    # Получить текущую сессию
    def telegram_session
      return nil unless session[:telegram_session]

      TelegramSession.from_h(session[:telegram_session])
    end

    # Установить сессию
    def telegram_session=(tg_session)
      if tg_session.nil?
        session.delete(:telegram_session)
      else
        session[:telegram_session] = tg_session.to_h
      end
    end

    # Очистить сессию
    def clear_telegram_session
      session.delete(:telegram_session)
    end
  end
end
