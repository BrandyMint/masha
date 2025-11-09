# frozen_string_literal: true

module Commands
    class VersionCommand < BaseCommand
      def call(*)
        respond_with :message, text: "Версия Маши: #{AppVersion}"
  end
end
end
