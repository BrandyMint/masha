# frozen_string_literal: true

class ProjectsCommand < BaseCommand
  provides_context_methods :new_project_slug_input

  NEW_PROJECT_SLUG_INPUT = :new_project_slug_input

  def call(action = nil, slug = nil, *)
    return respond_with :message, text: 'Вы не авторизованы для работы с проектами' if current_user.blank?

    case action
    when 'create'
      handle_create_command(slug)
    when nil
      show_projects
    else
      respond_with :message, text: 'Неизвестное действие. Используйте: /projects или /projects create [slug]'
    end
  end

  def new_project_slug_input(slug = nil, *)
    return respond_with :message, text: 'Slug не может быть пустым. Укажите slug для нового проекта:' if slug.blank?

    create_project(slug)
  end

  private

  def handle_create_command(slug)
    if slug.blank?
      save_context NEW_PROJECT_SLUG_INPUT
      return respond_with :message, text: 'Укажите slug (идентификатор) для нового проекта:'
    end

    create_project(slug)
  end

  def create_project(slug)
    project = current_user.projects.create!(name: slug, slug: slug)
    # Ensure user gets owner role for the new project
    current_user.set_role(:owner, project)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  rescue ActiveRecord::RecordInvalid => e
    respond_with :message, text: "Ошибка создания проекта: #{e.message}"
  end

  def show_projects
    projects = current_user.available_projects.alive.includes(:client)

    if projects.empty?
      text = build_multiline('Доступные проекты:', nil, 'У вас пока нет проектов.')
      text += "\n\n💡 *Создать новый проект:* /projects create"
    else
      text = build_multiline('Доступные проекты:', nil)
      projects.each do |project|
        project_info = project.name
        project_info += " (#{project.client.name})" if project.client&.name
        text += "• #{project_info}\n"
      end
      text += "\n\n💡 *Создать новый проект:* /projects create"
    end

    respond_with :message, text: text
  end

  def build_multiline(*lines)
    lines.compact.join("\n")
  end
end
