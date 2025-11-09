# frozen_string_literal: true

class MergeCommand < BaseCommand
  def call(email = nil, telegram_username = nil, *)
    unless developer?
      respond_with :message, text: 'Эта команда доступна только разработчику системы'
      return
    end

    if email.blank? || telegram_username.blank?
      respond_with :message, text: 'Использование: /merge email@example.com telegram_username'
      return
    end

    TelegramUserMerger.new(email, telegram_username, controller: controller).merge
  end
  end
