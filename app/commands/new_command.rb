# frozen_string_literal: true

class NewCommand < BaseCommand
  def call(slug = nil, *)
    if slug.blank?
      save_context :new_project_slug_input
      respond_with :message, text: 'Укажите slug (идентификатор) для нового проекта:'
      return
    end

    create_project(slug)
  end

    private

  def create_project(slug)
    project = current_user.projects.create!(name: slug, slug: slug)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  end
  end
