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
        if new_name.blank?
          respond_with :message, text: 'Укажите новое название проекта. Например: /rename project-slug "Новое название"'
          return
        end

        project = find_project(project_slug)
        unless project
          respond_with :message, text: "Проект с slug '#{project_slug}' не найден или недоступен"
          return
        end

        unless can_rename_project?(current_user, project)
          respond_with :message,
                       text: 'У вас нет прав для переименования этого проекта. ' \
                             'Только владелец (owner) может переименовывать проекты.'
          return
        end

        if new_name.length < 2
          respond_with :message, text: 'Название проекта должно содержать минимум 2 символа'
          return
        end

        if new_name.length > 255
          respond_with :message, text: 'Название проекта не может быть длиннее 255 символов'
          return
        end

        if Project.exists?(name: new_name)
          respond_with :message, text: 'Проект с таким названием уже существует'
          return
        end

        old_name = project.name
        old_slug = project.slug

        begin
          project.update!(name: new_name)
          respond_with :message, text: multiline(
            '✅ Проект успешно переименован!',
            "Старое название: #{old_name} (#{old_slug})",
            "Новое название: #{project.name} (#{project.slug})"
          )
        rescue ActiveRecord::RecordInvalid => e
          respond_with :message, text: "Ошибка при переименовании: #{e.message}"
        end
      end

      def show_projects_selection
        manageable_projects = current_user.available_projects.alive.joins(:memberships)
                                          .where(memberships: { user: current_user, role_cd: 0 })

        if manageable_projects.empty?
          respond_with :message,
                       text: 'У вас нет проектов, которые вы можете переименовывать. ' \
                             'Только владельцы (owners) могут переименовывать проекты.'
          return
        end

        save_context :rename_project_callback_query
        respond_with :message,
                     text: 'Выберите проект для переименования:',
                     reply_markup: {
                       inline_keyboard: manageable_projects.map do |p|
                         [{ text: "#{p.name} (#{p.slug})", callback_data: "rename_project:#{p.slug}" }]
                       end
                     }
      end

      def can_rename_project?(user, project)
        membership = user.membership_of(project)
        membership&.owner?
      end
    end
  end
end
