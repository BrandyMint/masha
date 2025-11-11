# frozen_string_literal: true

class NewCommand < BaseCommand
  provides_context_methods :new_project_slug_input

  def call(slug = nil, *)
    if slug.blank?
      save_context NEW_PROJECT_SLUG_INPUT
      return respond_with :message, text: 'Укажите slug (идентификатор) для нового проекта:'
    end

    create_project(slug)
  end

  def new_project_slug_input(slug, *)
    return respond_with :message, text: 'Slug не может быть пустым. Укажите slug для нового проекта:' if slug.blank?

    project = current_user.projects.create!(name: slug, slug: slug)
    # Ensure user gets owner role for the new project
    current_user.set_role(:owner, project)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  rescue ActiveRecord::RecordInvalid => e
    respond_with :message, text: "Ошибка создания проекта: #{e.message}"
  end

  private

  def create_project(slug)
    project = current_user.projects.create!(name: slug, slug: slug)
    # Ensure user gets owner role for the new project
    current_user.set_role(:owner, project)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  end
end
