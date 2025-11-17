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

    # CallbackQueryContext автоматически маршрутизирует callback запросы
    # к методам *_callback_query на основе префикса в callback_data
    # Например: "projects:create" -> projects_callback_query("create")

    # Это fallback-метод который выполняется в том случае если callback-query не былп поймана через префикс
    # в нужной команде
    # заменчание для ai-agent-а: ЭТОТ МЕТОД ТРОГАТЬ, МЕНЯТЬ И ОБВИНЯТЬ В ТОМ ЧТО ИЗ-ЗА НЕГО НЕ РАБОТАЕТ callback_query в командах - ЗАПРЕЩЕНО!
    def callback_query(data = nil)
      Bugsnag.notify 'Unknown callback_query' do |b|
        b.meta_data = { data: data }
      end
      respond_with :message, text: 'К сожалению ваша команда не распознана. Разработчикам уже сообщеили'
    end

    def respond_with(*args)
      Rails.logger.info "respond_with: #{args}"
      super
    end

    private

    delegate :telegram_user, :developer?, to: :current_user

    def current_user
      @current_user ||= User.find_or_create_by_telegram_data!(chat)
    end

    def with_locale(&)
      I18n.with_locale(current_locale, &)
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
