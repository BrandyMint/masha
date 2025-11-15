# frozen_string_literal: true

# Форматирует справочную информацию для команды /report.
# Поддерживает главную справку и детальные разделы с навигацией.
class ReportHelpFormatter
  def main_help
    <<~HELP
      📊 Команда /report - Универсальные отчеты

      🎯 Быстрый старт:
      • /report - отчет за сегодня
      • /report week - за текущую неделю
      • /report month - за текущий месяц

      📅 Периоды:
      today, yesterday, week, month, quarter
      2024-01-15 или 2024-01-01:2024-01-31

      🔍 Фильтры:
      project:slug - один проект
      projects:slug1,slug2 - несколько

      ⚙️ Опции:
      detailed - подробный формат с описаниями

      💡 Примеры:
      /report week project:work
      /report month detailed
      /report 2024-01-01:2024-01-31 projects:work,test

      ❓ Старые команды (/day, /summary, /hours) продолжат работать

      👉 Используйте кнопки ниже для подробной справки
    HELP
  end

  def main_keyboard
    {
      inline_keyboard: [
        [
          { text: '📅 Периоды', callback_data: 'report_periods:' },
          { text: '🔍 Фильтры', callback_data: 'report_filters:' }
        ],
        [
          { text: '⚙️ Опции', callback_data: 'report_options:' },
          { text: '💡 Примеры', callback_data: 'report_examples:' }
        ]
      ]
    }
  end

  def periods_help
    <<~HELP
      📅 Периоды отчетов

      Именованные периоды:
      • today - сегодня (по умолчанию)
      • yesterday - вчерашний день
      • week - текущая неделя (пн-вс)
      • month - текущий месяц
      • quarter - последние 3 месяца

      Конкретные даты:
      • 2024-01-15 - один день
      • 2024-01-01:2024-01-31 - диапазон дат

      Примеры:
      /report yesterday
      /report week
      /report month
      /report 2024-01-01:2024-01-15
    HELP
  end

  def filters_help
    <<~HELP
      🔍 Фильтры отчетов

      Фильтрация по проектам:
      • project:slug - отчет по одному проекту
      • projects:slug1,slug2 - по нескольким проектам

      Примеры:
      /report week project:work
      /report month project:personal
      /report today projects:work,test,hobby

      💡 Комбинируйте с периодами и опциями:
      /report week project:work detailed
      /report month projects:work,test
    HELP
  end

  def options_help
    <<~HELP
      ⚙️ Опции форматирования

      Доступные опции:
      • detailed - подробный формат с описаниями каждой записи

      Форматы вывода:
      • По умолчанию (summary) - группировка по проектам с итогами
      • detailed - все записи с описаниями, группировка по проектам

      Примеры:
      /report week detailed
      /report month project:work detailed
      /report today detailed

      💡 Опция detailed удобна для детального анализа работы
    HELP
  end

  def examples_help
    <<~HELP
      💡 Примеры использования

      Базовые отчеты:
      /report - отчет за сегодня
      /report yesterday - за вчерашний день
      /report week - за текущую неделю
      /report month - за текущий месяц

      С фильтрами:
      /report week project:work
      /report month projects:work,test
      /report today project:personal

      С опциями:
      /report week detailed
      /report month project:work detailed
      /report today detailed

      Конкретные даты:
      /report 2024-01-15
      /report 2024-01-01:2024-01-31
      /report 2024-01-01:2024-01-31 project:work

      Комбинации:
      /report week project:work detailed
      /report month projects:work,test detailed
      /report 2024-01-01:2024-01-15 project:work

      💡 Все параметры можно комбинировать в любом порядке
    HELP
  end

  def navigation_keyboard(section)
    buttons = base_navigation_buttons(section)

    {
      inline_keyboard: buttons
    }
  end

  private

  def base_navigation_buttons(current_section)
    buttons = []

    # First row: Back button
    buttons << [{ text: '◀️ Назад', callback_data: 'report_main:' }]

    # Second row: Navigation to other sections (excluding current)
    other_sections = section_buttons(current_section)
    buttons << other_sections if other_sections.any?

    buttons
  end

  def section_buttons(exclude_section)
    sections = {
      'periods' => { text: '📅 Периоды', callback_data: 'report_periods:' },
      'filters' => { text: '🔍 Фильтры', callback_data: 'report_filters:' },
      'options' => { text: '⚙️ Опции', callback_data: 'report_options:' },
      'examples' => { text: '💡 Примеры', callback_data: 'report_examples:' }
    }

    sections.reject { |key, _| key == exclude_section }.values
  end
end
