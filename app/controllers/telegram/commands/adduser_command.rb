# frozen_string_literal: true

module Telegram
  module Commands
    class AdduserCommand < BaseCommand
      def call(project_slug = nil, username = nil, role = 'member', *)
        if project_slug.blank?
          show_manageable_projects
          return
        end

        if username.blank?
          respond_with :message, text: 'Укажите никнейм пользователя (например: @username или username)'
          return
        end

        TelegramProjectManager.new(current_user, controller: controller)
                              .add_user_to_project(project_slug, username, role)
      end

      private

      def show_manageable_projects
        manageable_projects = current_user.available_projects.alive.joins(:memberships)
                                          .where(memberships: { user: current_user, role_cd: 0 })

        if manageable_projects.empty?
          respond_with :message, text: 'У вас нет проектов, в которые можно добавить пользователей'
          return
        end

        save_context :adduser_project_callback_query
        respond_with :message,
                     text: 'Выберите проект, в который хотите добавить пользователя:',
                     reply_markup: {
                       inline_keyboard: manageable_projects.map { |p| [{ text: p.name, callback_data: "adduser_project:#{p.slug}" }] }
                     }
      end
    end
  end
end
