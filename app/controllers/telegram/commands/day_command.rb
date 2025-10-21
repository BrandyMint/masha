# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Commands
    class DayCommand < BaseCommand
      def call(project_key = nil, *)
        current_date = Date.current

        # Base scope for current user's time shifts for today
        time_shifts = current_user.time_shifts
                                  .includes(:project)
                                  .where(date: current_date)
                                  .order(created_at: :asc)

        # Filter by project if key provided
        if project_key.present?
          project = find_project(project_key)
          unless project
            available_projects = current_user.available_projects.alive.map(&:slug).join(', ')
            respond_with :message, text: "Не найден проект '#{project_key}'. Доступные проекты: #{available_projects}"
            return
          end

          time_shifts = time_shifts.where(project: project)
        end

        # Check if there are any time shifts
        if time_shifts.empty?
          message = if project_key.present?
                      "Нет записей времени по проекту '#{project_key}' за сегодня"
                    else
                      'За сегодня еще нет записей времени. Добавьте время с помощью команды /add'
                    end
          respond_with :message, text: message
          return
        end

        # Build and send report
        text = build_day_report(time_shifts, project_key, current_date)
        respond_with :message, text: code(text), parse_mode: :Markdown
      end

      private

      def build_day_report(time_shifts, project_key, date)
        # Group by project
        grouped_shifts = time_shifts.group_by(&:project)
        total_hours = 0

        table = Terminal::Table.new do |t|
          t << %w[Проект Часы Описание]
          t << :separator

          grouped_shifts.each do |project, shifts|
            project_total = shifts.sum(&:hours)
            total_hours += project_total

            # First row for project with total hours
            t << [project.slug, project_total, '']

            # Individual entries for this project
            shifts.each do |shift|
              description = shift.description.presence || '·'
              t << ['', shift.hours, description]
            end

            # Add separator between projects (except last)
            t << :separator unless project == grouped_shifts.keys.last
          end

          t << :separator
          t << ['Итого за день', total_hours, '']
        end

        table.align_column(1, :right)

        title = if project_key.present?
                  "Часы по проекту '#{project_key}' за #{date}"
                else
                  "Часы за #{date}"
                end

        "#{title}\n\n#{table}"
      end
    end
  end
end
