# frozen_string_literal: true

module Commands
    class ReportCommand < BaseCommand
      def call(*)
        text = Reporter.new.list_by_days(current_user, group_by: :user).dup
        text << "\n"
        text << Reporter.new.list_by_days(current_user, group_by: :project)

        respond_with :message, text: code(text), parse_mode: :Markdown
  end
end
end
