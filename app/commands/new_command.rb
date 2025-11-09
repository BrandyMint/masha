# frozen_string_literal: true

class NewCommand < BaseCommand
  provides_context_methods :new_project_slug_input

  def call(slug = nil, *)
    if slug.blank?
      save_context NEW_PROJECT_SLUG_INPUT
      respond_with :message, text: 'Укажите slug (идентификатор) для нового проекта:'
      return
    end

    create_project(slug)
  end

  def new_project_slug_input(slug, *)
    if slug.blank?
      respond_with :message, text: 'Slug не может быть пустым. Укажите slug для нового проекта:'
      return
    end

    create_project(slug)
  rescue ActiveRecord::RecordInvalid => e
    respond_with :message, text: "Ошибка создания проекта: #{e.message}"
  end

  private

  def create_project(slug)
    project = current_user.projects.create!(name: slug, slug: slug)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  end
end
