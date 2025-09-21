# frozen_string_literal: true

module Telegram
  module Commands
    class VersionCommand < BaseCommand
      def call(*)
        respond_with :message, text: "Версия Маши: #{AppVersion}"
      end
    end
  end
end
