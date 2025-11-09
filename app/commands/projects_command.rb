# frozen_string_literal: true

class ProjectsCommand < BaseCommand
  def call(_data = nil, *)
    projects = current_user.available_projects.alive.includes(:client)

    if projects.empty?
      text = multiline('Доступные проекты:', nil, 'У вас пока нет проектов.')
    else
      text = multiline('Доступные проекты:', nil)
      projects.each do |project|
        project_info = project.name
        project_info += " (#{project.client.name})" if project.client
        text += "• #{project_info}\n"
      end
    end

    respond_with :message, text: text
  end
end
