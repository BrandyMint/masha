# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Commands
    class HoursCommand < BaseCommand
      def call(project_key = nil, *)
        three_months_ago = 3.months.ago.to_date

        # Base scope for current user's time shifts from last 3 months
        time_shifts = current_user.time_shifts
                                  .includes(:project)
                                  .where('date >= ?', three_months_ago)
                                  .order(date: :desc)

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
                      "Нет записей времени по проекту '#{project_key}' за последние 3 месяца"
                    else
                      'Нет записей времени за последние 3 месяца'
                    end
          respond_with :message, text: message
          return
        end

        # Build table
        text = build_hours_table(time_shifts, project_key)
        respond_with :message, text: code(text), parse_mode: :Markdown
      end

      private

      def build_hours_table(time_shifts, project_key)
        total_hours = 0

        table = Terminal::Table.new do |t|
          t << ['Дата', 'Проект', 'Часы']
          t << :separator

          time_shifts.each do |shift|
            t << [shift.date.to_s, shift.project.slug, shift.hours]
            total_hours += shift.hours
          end

          t << :separator
          t << ['Всего', '', total_hours]
        end

        table.align_column(2, :right)

        title = if project_key.present?
                  "Часы по проекту '#{project_key}' за последние 3 месяца"
                else
                  'Все часы за последние 3 месяца'
                end

        "#{title}\n\n#{table}"
      end
    end
  end
end
