# frozen_string_literal: true

# Deprecated: Use /report quarter instead.
# This command is kept for backward compatibility.
class HoursCommand < BaseCommand
  def call(project_key = nil, *)
    # Build args for ReportCommand
    args = ['quarter']
    args << "project:#{project_key}" if project_key.present?

    # Delegate to ReportCommand
    report_command = ReportCommand.new(controller)
    report_command.call(*args)

    # Add hint about new command
    hint = "\n\n💡 Теперь можно использовать /report quarter"
    hint += " project:#{project_key}" if project_key.present?

    respond_with :message, text: hint
  end
end
