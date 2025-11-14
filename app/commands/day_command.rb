# frozen_string_literal: true

# Deprecated: Use /report today instead.
# This command is kept for backward compatibility.
class DayCommand < BaseCommand
  def call(project_key = nil, *)
    # Build args for ReportCommand
    args = ['today']
    args << "project:#{project_key}" if project_key.present?

    # Delegate to ReportCommand
    report_command = ReportCommand.new(controller)
    report_command.call(*args)

    # Add hint about new command
    hint = "\n\n💡 Теперь можно использовать /report today"
    hint += " project:#{project_key}" if project_key.present?

    respond_with :message, text: hint
  end
end
