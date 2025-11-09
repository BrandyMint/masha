# frozen_string_literal: true

module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    Error = Class.new StandardError
    NotAvailableInPublicChat = Class.new Error

    include Telegram::Bot::UpdatesController::Session
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext

    # Раскидать по командным модулям
    include Telegram::ErrorHandling
    include Telegram::SessionHelpers
    include Telegram::CommandRegistration

    #before_action do
    #raise NotAvailableInPublicChat unless personal_chat?
    #end

    use_session!

    # use callbacks like in any other controllers
    around_action :with_locale


    # Core message handlers
    def message(message)
      text = if message.is_a?(String)
               message.strip
             else
               message['text']&.strip
             end

      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if text.blank?

      # Try to parse time tracking message in format: {hours} {project_slug} [description] or {project_slug} {hours} [description]
      parts = text.split(/\s+/)
      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if parts.length < 2

      tracker = TelegramTimeTracker.new(current_user, parts, self)
      result = tracker.parse_and_add

      if result[:error]
        respond_with :message, text: result[:error]
      elsif result[:success]
        # Success message is handled by the tracker
      else
        respond_with :message, text: 'Я не Алиса, мне нужна конкретика. Жми /help'
      end
    end

    def callback_query(data)
      Bugsnag.notify "Не определенный callback #{data}"
      respond_with :message, text: "Ошибка!"
    end

    private

    # Public methods needed by BaseCommand
    def find_current_user
      telegram_user.user || User
        .create_with(name: telegram_user.name, nickname: telegram_user.username)
        .find_or_create_by!(telegram_user_id: telegram_user.id)
    end

    # Public methods needed by BaseCommand
    def current_user
      return @current_user if defined? @current_user

      @current_user = find_current_user
    end

    def with_locale(&block)
      I18n.with_locale(current_locale, &block)
    end

    def current_locale
      if from
        I18n.locale # TODO брать у пользователя
      elsif chat
        I18n.locale # TODO брать и чата
      end
    end

    def developer?
      return false unless from

      from['id'] == ApplicationConfig.developer_telegram_id
    end

    def telegram_user
      @telegram_user ||= TelegramUser
        .create_with(chat.slice(*%w[first_name last_name username]))
        .create_or_find_by! id: chat.fetch('id')
    end
  end
end
