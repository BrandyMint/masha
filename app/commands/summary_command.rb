# frozen_string_literal: true

class SummaryCommand < BaseCommand
  HELP_TEXT = <<~TEXT
      📊 *Команда /summary - Статистика по проектам и пользователям*

      *Форматы использования:*
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

  def call(period = nil, *)
    if period.nil?
      respond_with :message, text: HELP_TEXT, parse_mode: :Markdown
      return
    end

    parsed_period = PeriodParser.parse(period)
    text = Reporter.new.projects_to_users_matrix(current_user, parsed_period)
    respond_with :message, text: code(text), parse_mode: :Markdown
  end
  end
