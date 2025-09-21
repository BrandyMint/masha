# frozen_string_literal: true

module Telegram
  module Commands
    class SummaryCommand < BaseCommand
      def call(period = 'week', *)
        text = Reporter.new.projects_to_users_matrix(current_user, period.to_sym)
        respond_with :message, text: code(text), parse_mode: :Markdown
      end
    end
  end
end
