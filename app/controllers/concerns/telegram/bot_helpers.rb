# frozen_string_literal: true

module Telegram
  module BotHelpers
    extend ActiveSupport::Concern

    # Public methods needed by BaseCommand
    def developer?
      return false unless from

      from['id'] == ApplicationConfig.developer_telegram_id
    end

    def current_locale
      if from
        # locale for user
        :ru
      elsif chat
        # locale for chat
        :ru
      end
    end

    def personal_chat?
      chat['id'] == from['id']
    end

    def session_key
      "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
    end

    def current_bot_id
      bot.token.split(':').first
    end

    # Public methods needed by BaseCommand
    def telegram_user
      @telegram_user ||= TelegramUser
                         .create_with(chat.slice(*%w[first_name last_name username]))
                         .create_or_find_by! id: chat.fetch('id')
    end

    def generate_start_link
      TelegramVerifier.get_link(
        uid: from['id'],
        nickname: from['username'],
        name: [from['first_name'], from['last_name']].compact.join(' ')
      )
    end
  end
end
