# frozen_string_literal: true

module Telegram
  module Commands
    class ProjectsCommand < BaseCommand
      def call(_data = nil, *)
        text = multiline 'Доступные проекты:', nil, current_user.available_projects.alive.join(', ')
        respond_with :message, text: text
      end
    end
  end
end
