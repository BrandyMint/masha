# frozen_string_literal: true

module Telegram
  module Commands
    class OwnerCommand < BaseCommand
      def call(*args)
        # Проверка прав доступа
        unless developer?
          respond_with :message, text: 'Эта команда доступна только разработчику системы'
          return
        end

        # Обработка различных режимов команды
        case args.size
        when 0
          show_all_projects
        when 1
          handle_single_argument(args.first)
        when 2
          change_project_owner(args[0], args[1])
        else
          show_usage_help
        end
      end

      private

      def show_all_projects
        projects = Project.includes(:memberships)
                          .order(:name)

        if projects.empty?
          respond_with :message, text: 'В системе нет проектов'
          return
        end

        table_data = build_projects_table(projects)
        table = Terminal::Table.new(headings: %w[Проект Slug Владелец Статус], rows: table_data)

        respond_with :message, text: code(table.to_s), parse_mode: :Markdown
      end

      def handle_single_argument(arg)
        case arg.downcase
        when 'active'
          show_filtered_projects(archived: false)
        when 'archived'
          show_filtered_projects(archived: true)
        when 'orphaned'
          show_orphaned_projects
        when 'search'
          respond_with :message, text: 'Использование: /owner search {текст_поиска}'
        else
          if arg.start_with?('search ')
            search_term = arg[7..] # Удаляем 'search '
            search_projects(search_term)
          else
            respond_with :message, text: "Неизвестный фильтр '#{arg}'. Доступные фильтры: active, archived, orphaned, search {текст}"
          end
        end
      end

      def show_filtered_projects(archived:)
        projects = Project.includes(:memberships)
                          .where(active: !archived)
                          .order(:name)

        status_text = archived ? 'архивных' : 'активных'
        if projects.empty?
          respond_with :message, text: "В системе нет #{status_text} проектов"
          return
        end

        table_data = build_projects_table(projects)
        table = Terminal::Table.new(headings: %w[Проект Slug Владелец], rows: table_data)

        respond_with :message, text: code("#{status_text.capitalize} проекты:\n#{table}"), parse_mode: :Markdown
      end

      def show_orphaned_projects
        ownerless_projects = Project.left_joins(:memberships)
                                    .where.not(projects: { id: nil })
                                    .where.not(id: Project.joins(:memberships).where(memberships: { role_cd: 0 }))
                                    .includes(:memberships)
                                    .order(:name)

        if ownerless_projects.empty?
          respond_with :message, text: 'Все проекты имеют владельцев'
          return
        end

        project_slugs = ownerless_projects.map(&:slug).join(', ')
        respond_with :message, text: "Проекты без владельца (#{ownerless_projects.size}):\n#{project_slugs}"
      end

      def search_projects(search_term)
        projects = Project.includes(:memberships)
                          .where('name ILIKE ? OR slug ILIKE ?', "%#{search_term}%", "%#{search_term}%")
                          .order(:name)

        if projects.empty?
          respond_with :message, text: "Проекты, содержащие '#{search_term}', не найдены"
          return
        end

        table_data = build_projects_table(projects)
        table = Terminal::Table.new(headings: %w[Проект Slug Владелец], rows: table_data)

        respond_with :message, text: code("Результаты поиска '#{search_term}':\n#{table}"), parse_mode: :Markdown
      end

      def change_project_owner(project_slug, new_owner_identifier)
        # Валидация и поиск проекта
        project = Project.find_by(slug: project_slug)
        unless project
          available_projects = Project.pluck(:slug).join(', ')
          respond_with :message, text: "Проект '#{project_slug}' не найден. Доступные проекты: #{available_projects}"
          return
        end

        # Поиск нового владельца
        new_owner = find_user_by_identifier(new_owner_identifier)
        unless new_owner
          respond_with :message,
                       text: "Пользователь '#{new_owner_identifier}' не найден в системе. " \
                             'Используйте email или Telegram username (@username)'
          return
        end

        # Проверка, что пользователь не является текущим владельцем
        current_owner = find_current_project_owner(project)
        if current_owner == new_owner
          respond_with :message,
                       text: "Пользователь '#{format_user_info_compact(new_owner)}' " \
                             "уже является владельцем проекта '#{project.name}'"
          return
        end

        # Выполнение смены владельца в транзакции
        ActiveRecord::Base.transaction do
          # Удалить старую роль owner, если она существует
          project.memberships.where(role_cd: 0).destroy_all

          # Создать новую membership с ролью owner
          project.memberships.create!(user: new_owner, role_cd: 0) # owner = 0

          # Присвоить старому владельцу роль viewer, если он существовал
          if current_owner
            existing_membership = current_owner.membership_of(project)
            if existing_membership
              existing_membership.update!(role_cd: 1) # viewer = 1
            else
              project.memberships.create!(user: current_owner, role_cd: 1) # viewer = 1
            end
          end

          # Логирование операции
          Rails.logger.info "Project owner changed: #{project.slug} - old: #{current_owner&.email} - new: #{new_owner.email}"
        end

        # Формирование ответа
        old_owner_info = current_owner ? format_user_info_compact(current_owner) : 'Нет владельца'
        new_owner_info = format_user_info_compact(new_owner)

        response_text = <<~TEXT
          ✅ Владелец проекта '#{project.name}' изменен!
          🔸 Старый владелец: #{old_owner_info}
          🔸 Новый владелец: #{new_owner_info}
          #{current_owner ? "📝 Старый владелец теперь имеет роль 'viewer'" : ''}
        TEXT

        respond_with :message, text: response_text
      rescue StandardError => e
        Rails.logger.error "Error changing project owner: #{e.message}"
        respond_with :message, text: "❌ Ошибка при смене владельца: #{e.message}"
      end

      def show_usage_help
        help_text = <<~HELP
          📋 *Команда /owner - управление владельцами проектов*

          *Просмотр владельцев:*
          `/owner` - показать все проекты и их владельцев
          `/owner active` - только активные проекты
          `/owner archived` - только архивные проекты
          `/owner orphaned` - проекты без владельцев
          `/owner search {текст}` - поиск проектов

          *Смена владельца:*
          `/owner {project_slug} {email|@username|user_id}`

          *Примеры:*
          `/owner my-project user@example.com`
          `/owner website @username`
          `/owner app 123`

          ⚠️ *Доступно только разработчику системы*
        HELP

        respond_with :message, text: help_text, parse_mode: :Markdown
      end

      def build_projects_table(projects)
        projects.map do |project|
          owner = find_project_owner(project)
          status = project.active? ? 'Активный' : 'Архивный'

          [
            truncate_string(project.name, 30),
            project.slug,
            owner,
            status
          ]
        end
      end

      def find_project_owner(project)
        owner_membership = project.memberships.find_by(role_cd: 0) # owner = 0
        return 'Нет владельца' unless owner_membership

        user = owner_membership.user
        format_user_info_compact(user)
      end

      def find_current_project_owner(project)
        owner_membership = project.memberships.find_by(role_cd: 0) # owner = 0
        owner_membership&.user
      end

      def find_user_by_identifier(identifier)
        # Попытка найти по email (check for valid email format)
        return User.find_by(email: identifier) if identifier.match?(/\A.+@.+\..+\z/)

        # Попытка найти по telegram username
        clean_identifier = identifier.delete_prefix('@')
        telegram_user = TelegramUser.find_by(username: clean_identifier)
        return telegram_user.user if telegram_user

        # Попытка найти по ID
        return User.find_by(id: identifier.to_i) if identifier.match?(/\A\d+\z/)

        # Попытка найти по имени
        User.find_by(name: identifier)
      end

      def format_user_info_compact(user)
        parts = []
        parts << user.name if user.name.present?
        parts << user.email if user.email.present?
        parts << "@#{user.telegram_user.username}" if user.telegram_user&.username
        parts.empty? ? "ID: #{user.id}" : parts.join(' ')
      end

      def truncate_string(string, max_length)
        return string if string.length <= max_length

        "#{string[0...max_length - 3]}..."
      end
    end
  end
end
