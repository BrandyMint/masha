# frozen_string_literal: true

module Telegram
  module Commands
    class HelpCommand < BaseCommand
      def call(*)
        respond_with :message, text: help_message
      end
    end
  end
end
