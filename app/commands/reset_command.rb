# frozen_string_literal: true

class ResetCommand < BaseCommand
  include Telegram::ErrorHandling

  def call(*_args)
    reset_session
    respond_with :message, text: t('telegram.commands.reset.success')
  end

    private

  def reset_session
    # Очищаем Telegram сессию
    clear_telegram_session

    # Очищаем контекст telegram-bot
    reset_session_context

    # Очищаем все ключи сессии, которые относятся к Telegram
    telegram_session_keys.each do |key|
      session.delete(key)
    end
  end

  def reset_session_context
    # Сбрасываем контекст, если он есть
    respond_with :message, text: '' if session[:context]
    session.delete(:context)
  end

  def telegram_session_keys
    # Список ключей сессии, которые относятся к Telegram
    session.keys.select do |key|
      key.to_s.start_with?('telegram_') ||
        %w[context edit_client_key client_name edit_project_key].include?(key.to_s)
    end
  end
  end
