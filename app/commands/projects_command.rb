# frozen_string_literal: true

class ProjectsCommand < BaseCommand
  def call(_data = nil, *)
    return respond_with :message, text: 'Вы не аваторизованы для работы с клиентами' if current_user.blank?
    projects = current_user.available_projects.alive.includes(:client)

    if projects.empty?
      text = build_multiline('Доступные проекты:', nil, 'У вас пока нет проектов.')
    else
      text = build_multiline('Доступные проекты:', nil)
      projects.each do |project|
        project_info = project.name
        project_info += " (#{project.client.name})" if project.client&.name
        text += "• #{project_info}\n"
      end
    end

    respond_with :message, text: text
  end

  private

  def build_multiline(*lines)
    lines.compact.join("\n")
  end
end
