# frozen_string_literal: true

class BroadcastNotificationJob < ApplicationJob
  queue_as :default

  def perform(message, telegram_user_ids)
    telegram_user_ids.each do |user_id|
      TelegramNotificationJob.perform_later(user_id: user_id, message: message)
    end
  end
end
