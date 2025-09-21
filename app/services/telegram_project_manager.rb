# frozen_string_literal: true

class TelegramProjectManager
  def initialize(user, controller:)
    @user = user
    @controller = controller
  end

  def add_user_to_project(project_slug, username, role)
    # Remove @ from username if present
    username = username.delete_prefix('@')

    project = find_project(project_slug)
    unless project
      respond_with_error("Не найден проект '#{project_slug}'. Вам доступны: #{@user.available_projects.alive.join(', ')}")
      return
    end

    # Check if current user can manage this project (owner or viewer role)
    membership = @user.membership_of(project)
    unless membership&.owner?
      respond_with_error("У вас нет прав для добавления пользователей в проект '#{project.slug}', " \
                         'только владелец (owner) может это сделать.')
      return
    end

    # Validate role
    role = role.downcase
    unless Membership.roles.keys.include?(role)
      respond_with_error("Неверная роль '#{role}'. Доступные роли: #{Membership.roles.keys.join(', ')}")
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
        respond_with_error("Пользователь '@#{username}' уже участвует в проекте '#{project.slug}' " \
                           "с ролью #{existing_membership.role}")
        return
      end

      # Add user to project
      user.set_role(role.to_sym, project)
      respond_with_success("Пользователь '@#{username}' добавлен в проект '#{project.slug}' с ролью '#{role}'")
    else
      # User not found or not linked - create invitation
      existing_invite = Invite.find_by(telegram_username: username, project: project)
      if existing_invite
        respond_with_error("Приглашение для пользователя '@#{username}' в проект '#{project.slug}' " \
                           "уже отправлено с ролью '#{existing_invite.role}'")
        return
      end

      # Create invitation
      Invite.create!(
        user: @user,
        project: project,
        telegram_username: username,
        role: role
      )

      respond_with_success("Создано приглашение для пользователя '@#{username}' в проект '#{project.slug}' с ролью '#{role}'. " \
                           'Когда пользователь присоединится к боту, он автоматически будет добавлен в проект.')
    end
  end

  private

  def find_project(key)
    @user.available_projects.alive.find_by(slug: key)
  end

  def respond_with_error(text)
    @controller.respond_with :message, text: text
  end

  def respond_with_success(text)
    @controller.respond_with :message, text: text
  end
end
