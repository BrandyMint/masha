# frozen_string_literal: true

module Telegram
  module ErrorHandling
    extend ActiveSupport::Concern

    private

    def notify_bugsnag(message)
      Rails.logger.err message
      Bugsnag.notify message do |b|
        b.metadata = payload
      end
    end

    def logger
      Rails.application.config.telegram_updates_controller.logger
    end
  end
end
