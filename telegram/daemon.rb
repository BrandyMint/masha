#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application',  __FILE__)
require_relative APP_PATH
Rails.application.require_environment!

require 'telegram/bot'

token = ENV['TELEGRAM_TOKEN'] || Rails.credentials.telegram_api_key

Telegram::Bot::Client.run(token, logger: Logger.new($stderr)) do |bot|
  bot.logger.info('Bot has been started')
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/projects'
      when '/start' # "/start@MashTimeBot"

      else
        if message.left_chat_member && message.left_chat_member.username == Settings.telegram_bot_name
          bot.logger.info("Leave chat #{message.chat.title}")

        elsif message.new_chat_members.any? && message.new_chat_members.map(&:username).include?(Settings.telegram_bot_name)
          bot.logger.info("Added to chat #{message.chat.title}")
          bot.api.send_message(chat_id: message.chat.id, text: "Привет всем!\nМеня зовут Маша. Я помогаю учитывать ресурсы.\nПришлите /start@#{Settings.telegram_bot_name} чтобы познакомиться лично.")

        else
          bot.logger.info("Unknown message text #{message.inspect}")
        end
      end
    else
      bot.logger.info("Unknown message type #{message.inspect}")
    end
  end
end
