# frozen_string_literal: true

module Telegram
  module TimeTracking
    extend ActiveSupport::Concern

    private

    def parse_time_tracking_message(parts)
      first_part = parts[0]
      second_part = parts[1]
      description = parts[2..].join(' ') if parts.length > 2

      # Check if first part is numeric (hours format)
      if numeric?(first_part)
        hours = first_part
        project_slug = second_part
      elsif numeric?(second_part)
        # Second part is numeric (project_slug hours format)
        project_slug = first_part
        hours = second_part
      else
        return { error: 'Не удалось определить часы и проект. Используйте формат: "2.5 project описание" или "project 2.5 описание"' }
      end

      # Validate project exists
      project = find_project(project_slug)
      unless project
        available_projects = current_user.available_projects.alive.map(&:slug).join(', ')
        return { error: "Не найден проект '#{project_slug}'. Доступные проекты: #{available_projects}" }
      end

      { hours: hours, project_slug: project_slug, description: description }
    end

    def numeric?(str)
      return false unless str.is_a?(String)

      str.match?(/\A\d+([.,]\d+)?\z/)
    end

    def add_time_entry(project_slug, hours, description = nil)
      project = find_project(project_slug)

      project.time_shifts.create!(
        date: Time.zone.today,
        hours: hours.to_s.tr(',', '.').to_f,
        description: description || '',
        user: current_user
      )

      respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
    rescue StandardError => e
      respond_with :message, text: "Ошибка при добавлении времени: #{e.message}"
    end
  end
end
