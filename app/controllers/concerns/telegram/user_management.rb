# frozen_string_literal: true

module Telegram
  module UserManagement
    extend ActiveSupport::Concern

    # Public methods needed by BaseCommand
    def format_user_info(user)
      telegram_info = if user.telegram_user
                        "**@#{user.telegram_user.username || 'нет_ника'}** (#{user.telegram_user.name})"
                      else
                        '*Telegram не привязан*'
                      end

      email_info = user.email.present? ? "📧 #{user.email}" : '📧 *Email не указан*'

      projects_info = if user.projects.any?
                        projects_list = user.projects.map(&:name).join(', ')
                        "📋 Проекты: #{projects_list}"
                      else
                        '📋 *Нет проектов*'
                      end

      [telegram_info, email_info, projects_info].join("\n")
    end

    # Public methods needed by BaseCommand
    def add_user_to_project(project_slug, username, role)
      # Remove @ from username if present
      username = username.delete_prefix('@')

      project = find_project(project_slug)
      unless project
        respond_with :message, text: "Не найден проект '#{project_slug}'. Вам доступны: #{current_user.available_projects.alive.join(', ')}"
        return
      end

      # Check if current user can manage this project (owner or viewer role)
      membership = current_user.membership_of(project)
      unless membership&.owner?
        respond_with :message, text: "У вас нет прав для добавления пользователей в проект '#{project.slug}', " \
                                     'только владелец (owner) может это сделать.'
        return
      end

      # Validate role
      role = role.downcase
      unless Membership.roles.keys.include?(role)
        respond_with :message, text: "Неверная роль '#{role}'. Доступные роли: #{Membership.roles.keys.join(', ')}"
        return
      end

      # Find user by Telegram username
      telegram_user = TelegramUser.find_by(username: username)

      if telegram_user&.user
        # User exists and is linked to system
        user = telegram_user.user

        # Check if user is already in project
        existing_membership = user.membership_of(project)
        if existing_membership
          respond_with :message, text: "Пользователь '@#{username}' уже участвует в проекте '#{project.slug}' " \
                                       "с ролью #{existing_membership.role}"
          return
        end

        # Add user to project
        user.set_role(role.to_sym, project)
        respond_with :message, text: "Пользователь '@#{username}' добавлен в проект '#{project.slug}' с ролью '#{role}'"
      else
        # User not found or not linked - create invitation
        existing_invite = Invite.find_by(telegram_username: username, project: project)
        if existing_invite
          respond_with :message,
                       text: "Приглашение для пользователя '@#{username}' в проект '#{project.slug}' " \
                             "уже отправлено с ролью '#{existing_invite.role}'"
          return
        end

        # Create invitation
        Invite.create!(
          user: current_user,
          project: project,
          telegram_username: username,
          role: role
        )

        respond_with :message, text: "Создано приглашение для пользователя '@#{username}' в проект '#{project.slug}' с ролью '#{role}'. " \
                                     'Когда пользователь присоединится к боту, он автоматически будет добавлен в проект.'
      end
    end

    # Public methods needed by BaseCommand
    def find_current_user
      telegram_user.user || User
        .create_with(name: telegram_user.name, nickname: telegram_user.username)
        .find_or_create_by!(telegram_user_id: telegram_user.id)
    end

    # Public methods needed by BaseCommand
    def current_user
      return @current_user if defined? @current_user

      @current_user = find_current_user
    end

    # Public methods needed by BaseCommand
    def logged_in?
      current_user.present?
    end
  end
end
