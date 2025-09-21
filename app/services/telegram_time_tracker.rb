# frozen_string_literal: true

class TelegramTimeTracker
  def initialize(user, message_parts, controller)
    @user = user
    @message_parts = message_parts
    @controller = controller
  end

  def parse_and_add
    return { error: 'Я не Алиса, мне нужна конкретика. Жми /help' } if @message_parts.length < 2

    result = parse_time_tracking_message
    return result if result[:error]

    if result[:hours] && result[:project_slug]
      message = add_time_entry(result[:project_slug], result[:hours], result[:description])
      @controller.respond_with :message, text: message
      { success: true }
    else
      { error: 'Я не Алиса, мне нужна конкретика. Жми /help' }
    end
  end

  private

  def parse_time_tracking_message
    first_part = @message_parts[0]
    second_part = @message_parts[1]
    description = @message_parts[2..].join(' ') if @message_parts.length > 2

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
      available_projects = @user.available_projects.alive.map(&:slug).join(', ')
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
      user: @user
    )

    "Отметили в #{project.name} #{hours} часов"
  rescue StandardError => e
    "Ошибка при добавлении времени: #{e.message}"
  end

  def find_project(key)
    @user.available_projects.alive.find_by(slug: key)
  end
end
