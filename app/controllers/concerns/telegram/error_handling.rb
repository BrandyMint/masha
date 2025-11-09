# frozen_string_literal: true

module Telegram
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from AbstractController::ActionNotFound, with: :handle_action_not_found
      rescue_from StandardError, with: :handle_error
    end

    private

    def notify_bugsnag(message_or_error)
      Rails.logger.error "Error in Telegram controller: #{message_or_error.is_a?(Exception) ? message_or_error.message : message_or_error}"
      Rails.logger.error message_or_error.backtrace.join("\n") if message_or_error.is_a?(Exception)

      Bugsnag.notify(message_or_error) do |b|
        b.user = current_user if respond_to?(:current_user)
        b.meta_data = payload if defined?(payload)
        yield b if block_given?
      end
    end

    def handle_action_not_found(exception)
      notify_bugsnag(exception)
      respond_with :message, text: t('telegram.commands.unknown_command')
    end

    def handle_error(exception)
      notify_bugsnag(exception) do |payload|
        payload.add_metadata(:telegram, {
          from: "#{self.class.name}##{caller_locations(1,1).first.label}",
          user: current_user&.id,
          chat_id: chat&.id
        })
      end

      respond_with :message, text: t('telegram.commands.error_occurred')
    end
  end
end
