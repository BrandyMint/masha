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

    # before_action do
    # raise NotAvailableInPublicChat unless personal_chat?
    # end

    # use callbacks like in any other controllers
    around_action :with_locale

    # Core message handlers
    def message(payload)
      raise 'message не может передаваться строкой, это нарушает спецификацию gem telegram-bot' if payload.is_a?(String)

      text = payload.fetch('text')&.strip

      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if text.blank?

      # Try to parse time tracking message in format: {hours} {project_slug} [description] or {project_slug} {hours} [description]
      parts = text.split(/\s+/)
      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if parts.length < 2

      tracker = TelegramTimeTracker.new(telegram_user, text)
      result = tracker.parse_and_add

      if result[:error]
        respond_with :message, text: result[:error]
      elsif result[:success]
        respond_with :message, text: result[:message]
        # Success message is handled by the tracker
      else
        respond_with :message, text: 'Я не Алиса, мне нужна конкретика. Жми /help'
      end
    end

    def callback_query(data)
      # Route callback query to the appropriate command based on prefix
      case data
      when /^projects:/
        projects_callback_query(data)
      when /^client:/
        # Will be handled by client_command if implemented
        Bugsnag.notify "Callback query для client: #{data}"
        respond_with :message, text: 'Ошибка!'
      else
        Bugsnag.notify "Не определенный callback #{data}"
        respond_with :message, text: 'Ошибка!'
      end
    end

    def test!(*_args)
      respond_with :message, text: 'test passed'
      reply_with :message, text: 'Replied'
    end

    def telegram_user
      @telegram_user ||= TelegramUser
                         .create_with(chat.slice(*%w[first_name last_name username]))
                         .create_or_find_by! id: chat.fetch('id')
    end

    def current_user
      telegram_user.user
    end

    def developer?
      telegram_user.developer?
    end

    def respond_with(*args)
      Rails.logger.info "respond_with: #{args}"
      super(*args)
    end

    def universal_command!(*_args)
      debugger
    end

    private

    def with_locale(&block)
      I18n.with_locale(current_locale, &block)
    end

    # def action_for_command(cmd)
    ## Для всех команда одна команда
    # "universal_command!"
    # #"#{cmd.downcase}!"
    # end

    # def action_for_message_orig
    # cmd, args = Commands.command_from_text(payload['text'], bot_username)
    # return unless cmd
    # [[action_for_command(cmd), {type: :command, command: cmd}], args]
    # end

    # def action_for_message
    # val = message_context_session.delete(:context)
    # context = val&.to_s
    # action_for_message_orig || (context && begin
    # args = payload['text']&.split || []
    # action = action_for_message_context(context)
    # [[action, {type: :message_context, context: context}], args]
    # end)
    # end

    def current_locale
      if from
        I18n.locale # TODO: брать у пользователя
      elsif chat
        I18n.locale # TODO: брать и чата
      end
    end
  end
end
