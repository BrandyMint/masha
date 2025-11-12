# frozen_string_literal: true

class BroadcastNotificationJob < ApplicationJob
  queue_as :default

  def perform(message)
    return if message.blank?
    TelegramUser.select(:id).find_each do |user|
      TelegramNotificationJob.perform_later(user_id: user.id, message: message)
    end
  end
end
