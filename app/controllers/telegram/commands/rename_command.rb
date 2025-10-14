# frozen_string_literal: true

module Telegram
  module Commands
    class RenameCommand < BaseCommand
      def call(project_slug = nil, *name_parts)
        if project_slug.present?
          # Прямое переименование: /rename project-slug "Новое название"
          new_name = name_parts.join(' ')
          rename_project_directly(project_slug, new_name)
        else
          # Показать список проектов для выбора
          show_projects_selection
        end
      end

      private

      def rename_project_directly(project_slug, new_name)
        project = find_project(project_slug)
        unless project
          respond_with :message, text: format(RenameConfig::MESSAGES[:project_not_found], project_slug)
          return
        end

        service = ProjectRenameService.new
        result = service.call(current_user, project, new_name)

        respond_with :message, text: result[:message]
      end

      def show_projects_selection
        service = ProjectRenameService.new
        manageable_projects = service.manageable_projects(current_user)

        if manageable_projects.empty?
          respond_with :message, text: RenameConfig::MESSAGES[:no_manageable_projects]
          return
        end

        save_context :rename_project_callback_query
        respond_with :message,
                     text: RenameConfig::MESSAGES[:select_project],
                     reply_markup: {
                       inline_keyboard: manageable_projects.map do |p|
                         [{ text: "#{p.name} (#{p.slug})", callback_data: "rename_project:#{p.slug}" }]
                       end
                     }
      end
    end
  end
end
