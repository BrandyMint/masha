# frozen_string_literal: true

class TelegramNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id:, message:)
    telegram_user = TelegramUser.find_by(id: user_id)
    return unless telegram_user

    Telegram.bot.send_message(
      chat_id: user_id,
      text: message
    )
  rescue Telegram::Bot::Forbidden, Telegram::Bot::Error => e
    Bugsnag.notify e
    Rails.logger.warn "Failed to send Telegram notification to user #{user_id}: #{e.message}"
  end
end
