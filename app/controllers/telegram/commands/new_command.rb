# frozen_string_literal: true

module Telegram
  module Commands
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
      rescue ActiveRecord::RecordInvalid => e
        Bugsnag.notify e do |b|
          b.meta_data = { slug: }
        end
        respond_with :message, text: "Ошибка создания проекта #{e.record.errors.messages.to_json}"
      end
    end
  end
end
