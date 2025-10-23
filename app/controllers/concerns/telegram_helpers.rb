# frozen_string_literal: true

module TelegramHelpers
  extend ActiveSupport::Concern

  private

  def parse_time_tracking_message(parts)
    first_part = parts[0]
    second_part = parts[1]
    description = parts[2..].join(' ') if parts.length > 2

    # Check if first part is numeric (hours format)
    if numeric?(first_part)
      hours = first_part
      project_slug = second_part
    elsif numeric?(second_part)
      # Second part is numeric (project_slug hours format)
      project_slug = first_part
      hours = second_part
    else
      return { error: 'Не удалось определить часы и проект. Используйте формат: "2.5 project описание" или "project 2.5 описание"' }
    end

    # Validate project exists
    project = find_project(project_slug)
    unless project
      available_projects = current_user.available_projects.alive.map(&:slug).join(', ')
      return { error: "Не найден проект '#{project_slug}'. Доступные проекты: #{available_projects}" }
    end

    { hours: hours, project_slug: project_slug, description: description }
  end

  def numeric?(str)
    return false unless str.is_a?(String)

    str.match?(/\A\d+([.,]\d+)?\z/)
  end

  def add_time_entry(project_slug, hours, description = nil)
    project = find_project(project_slug)

    project.time_shifts.create!(
      date: Time.zone.today,
      hours: hours.to_s.tr(',', '.').to_f,
      description: description || '',
      user: current_user
    )

    respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
  rescue StandardError => e
    respond_with :message, text: "Ошибка при добавлении времени: #{e.message}"
  end

  def developer?
    return false unless from

    from['id'] == ApplicationConfig.developer_telegram_id
  end

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

  def help_message
    commands = [
      '/help - Эта подсказка',
      '/version - Версия Маши',
      '/projects - Список проектов',
      '/attach {projects_slug} - Указать проект этого чата',
      '/add {project_slug} {hours} [description] - Отметить время',
      '/edit - Редактировать ранее добавленную запись времени',
      '/rename [project_slug] "Новое название" - Переименовать проект (только для владельцев)',
      '/new [project_slug] - Создать новый проект',
      '/adduser {project_slug} {username} [role] - Добавить пользователя в проект (роли: owner, viewer, member)',
      '/report - Детальный отчёт по командам и проектам',
      '/day - Отчёт за день',
      '/rename - Переименовка проекта',
      '/summary {week|month}- Сумарный отчёт за период',
      '/hours [project_slug] - Все часы за последние 3 месяца',
      '',
      'Быстрое добавление времени:',
      '{hours} {project_slug} [description] - например: "2.5 myproject работал над фичей"',
      '{project_slug} {hours} [description] - например: "myproject 2.5 работал над фичей"'
    ]

    # Add developer commands if user is developer
    if developer?
      commands << '# Только для разработчика'
      commands << '/users - Список всех пользователей системы (только для разработчика)'
      commands << '/merge {email} {telegram_username} - Объединить аккаунты (только для разработчика)'
      commands << '/owner - Управление владельцами проектов (только для разработчика)'
    end

    multiline(commands)
  end

  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end

  def generate_start_link
    TelegramVerifier.get_link(
      uid: from['id'],
      nickname: from['username'],
      name: [from['first_name'], from['last_name']].compact.join(' ')
    )
  end

  def current_user
    return @current_user if defined? @current_user

    @current_user = find_current_user
  end

  def find_current_user
    telegram_user.user || User
      .create_with(name: telegram_user.name, nickname: telegram_user.username)
      .find_or_create_by!(telegram_user_id: telegram_user.id)
  end

  def logged_in?
    current_user.present?
  end

  def current_locale
    if from
      # locale for user
      :ru
    elsif chat
      # locale for chat
      :ru
    end
  end

  def code(text)
    multiline '```', text, '```'
  end

  def is_personal_chat?
    chat['id'] == from['id']
  end

  def find_project(key)
    current_user.available_projects.alive.find_by(slug: key)
  end

  def logger
    Rails.application.config.telegram_updates_controller.logger
  end

  # In this case session will persist for user only in specific chat.
  # Same user in other chat will have different session.
  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end

  def attached_project
    current_user.available_projects.find_by(telegram_chat_id: chat['id'])
  end

  def current_bot_id
    bot.token.split(':').first
  end

  def telegram_user
    @telegram_user ||= TelegramUser
                       .create_with(chat.slice(*%w[first_name last_name username]))
                       .create_or_find_by! id: chat.fetch('id')
  end

  def notify_bugsnag(message)
    Rails.logger.err message
    Bugsnag.notify message do |b|
      b.metadata = payload
    end
  end
end
