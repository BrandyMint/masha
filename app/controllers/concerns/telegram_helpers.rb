# frozen_string_literal: true

module TelegramHelpers
  extend ActiveSupport::Concern

  included do
    include Telegram::TimeTracking
    include Telegram::UserManagement
    include Telegram::ProjectHelpers
    include Telegram::BotHelpers
    include Telegram::FormattingHelpers
    include Telegram::ErrorHandling
  end
end
