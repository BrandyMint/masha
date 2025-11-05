# frozen_string_literal: true

module Telegram
  module ProjectHelpers
    extend ActiveSupport::Concern

    # Public methods needed by BaseCommand
    def find_project(key)
      current_user.available_projects.alive.find_by(slug: key)
    end

    # Public methods needed by BaseCommand
    def attached_project
      current_user.available_projects.find_by(telegram_chat_id: chat['id'])
    end
  end
end
