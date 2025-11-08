# frozen_string_literal: true

module Telegram
  module ErrorHandling
    extend ActiveSupport::Concern

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

    def logger
      Rails.application.config.telegram_updates_controller.logger
    end
  end
end
