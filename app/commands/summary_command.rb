# frozen_string_literal: true

class SummaryCommand < BaseCommand
  HELP_TEXT = <<~TEXT
    📊 *Команда /summary - Статистика по проектам и пользователям*

    *Рекомендуем использовать новую команду /report:*
    • `/report week` - текущая неделя
    • `/report month` - текущий месяц

    *Форматы использования /summary:*
    • `/summary day` - сегодня
    • `/summary week` - текущая неделя
    • `/summary month` - текущий месяц
    • `/summary last_month` - прошлый месяц
    • `/summary last_week` - прошлая неделя

    *Конкретные даты:*
    • `/summary 2024-11-05` - конкретная дата
    • `/summary 2024-11` - конкретный месяц
    • `/summary 2024-11-01..2024-11-05` - диапазон дат
    • `/summary 2024-10..2024-11` - диапазон месяцев

    *Примеры:*
    `/summary last_month` - статистика за прошлый месяц
    `/summary 2024-11-01..2024-11-07` - за первую неделю ноября
    `/summary 2024-10` - за октябрь 2024

    _Формат даты: ГГГГ-ММ-ДД, формат месяца: ГГГГ-ММ_
  TEXT

  # Map simple periods to ReportCommand
  REPORT_PERIODS = {
    'day' => 'today',
    'week' => 'week',
    'month' => 'month'
  }.freeze

  def call(period = nil, *)
    if period.nil?
      respond_with :message, text: HELP_TEXT, parse_mode: :Markdown
      return
    end

    # Delegate simple periods to ReportCommand
    if REPORT_PERIODS.key?(period)
      report_period = REPORT_PERIODS[period]
      report_command = ReportCommand.new(controller)
      report_command.call(report_period)

      hint = "\n\n💡 Теперь можно использовать /report #{report_period}"
      respond_with :message, text: hint
      return
    end

    # Keep existing functionality for other periods
    parsed_period = PeriodParser.parse(period)
    text = Reporter.new.projects_to_users_matrix(current_user, parsed_period)

    # Add hint for complex periods too
    hint = "\n\n💡 Для простых периодов используйте /report week или /report month"
    respond_with :message, text: code(text) + hint, parse_mode: :Markdown
  end
end
