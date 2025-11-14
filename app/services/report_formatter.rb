# frozen_string_literal: true

require 'terminal-table'

# Форматирует структурированные данные отчетов в текстовый формат для вывода.
# Поддерживает два формата: summary (краткий) и detailed (подробный с описаниями).
class ReportFormatter
  attr_reader :report_data, :format

  def initialize(report_data, format: :summary)
    @report_data = report_data
    @format = format
  end

  def format_report
    return empty_report_message if report_data[:entries].empty?

    case format
    when :summary
      format_summary
    when :detailed
      format_detailed
    else
      raise ArgumentError, "Unknown format: #{format}"
    end
  end

  private

  def empty_report_message
    period_str = format_period(report_data[:period])
    "Нет записей времени за период: #{period_str}"
  end

  def format_summary
    title = format_period_title
    table = build_summary_table

    "#{title}\n\n#{table}"
  end

  def format_detailed
    title = format_period_title
    table = build_detailed_table

    "#{title}\n\n#{table}"
  end

  def format_period_title
    period = report_data[:period]
    period_str = format_period(period)

    "Отчет за #{period_str}"
  end

  def format_period(period)
    from_date = period[:from]
    to_date = period[:to]

    if from_date == to_date
      from_date.to_s
    else
      "#{from_date} - #{to_date}"
    end
  end

  def build_summary_table
    grouped = report_data[:grouped_by_project]
    total_hours = report_data[:total_hours]

    table = Terminal::Table.new do |t|
      t << %w[Проект Часы Записей]
      t << :separator

      grouped.each do |project_slug, data|
        t << [project_slug, data[:hours], data[:count]]
      end

      t << :separator
      t << ['Итого', total_hours, report_data[:entries].count]
    end

    # Align hours and count columns to the right
    table.align_column(1, :right)
    table.align_column(2, :right)

    table.to_s
  end

  def build_detailed_table
    entries = report_data[:entries]
    total_hours = report_data[:total_hours]

    # Group entries by project for display
    grouped_entries = entries.group_by { |entry| entry[:project] }

    table = Terminal::Table.new do |t|
      t << %w[Проект Часы Описание]
      t << :separator

      grouped_entries.each_with_index do |(project, project_entries), index|
        project_total = project_entries.sum { |e| e[:hours] }

        # Project header row with total
        t << [project.slug, project_total, '']

        # Individual entries for this project
        project_entries.each do |entry|
          description = entry[:description].presence || '·'
          t << ['', entry[:hours], description]
        end

        # Separator between projects (except after last project)
        t << :separator unless index == grouped_entries.size - 1
      end

      t << :separator
      t << ['Итого', total_hours, '']
    end

    # Align hours column to the right
    table.align_column(1, :right)

    table.to_s
  end
end
