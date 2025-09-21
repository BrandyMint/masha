# frozen_string_literal: true

module TelegramCallbacks
  extend ActiveSupport::Concern

  def callback_query(data)
    edit_message :text, text: "Вы выбрали #{data}"
  end

  def select_project_callback_query(project_slug)
    save_context :add_time
    project = find_project project_slug
    session[:add_time_project_id] = project.id
    edit_message :text,
                 text: "Вы выбрали проект #{project.slug}, теперь укажите время и через пробел комментарий (12 делал то-то)"
  end

  def adduser_project_callback_query(project_slug)
    project = find_project(project_slug)
    unless project
      edit_message :text, text: 'Проект не найден'
      return
    end

    # Check permissions - only owners can add users
    membership = current_user.membership_of(project)
    unless membership&.owner?
      edit_message :text, text: 'У вас нет прав для добавления пользователей в этот проект, только владелец (owner) может это сделать.'
      return
    end

    session[:adduser_project_slug] = project_slug
    save_context :adduser_username_input
    edit_message :text, text: "Проект: #{project.name}\nТеперь введите никнейм пользователя (например: @username или username):"
  end

  def adduser_username_input(username, *)
    username = username.delete_prefix('@') if username.start_with?('@')
    session[:adduser_username] = username

    save_context :adduser_role_callback_query
    respond_with :message,
                 text: "Пользователь: @#{username}\nВыберите роль для пользователя:",
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: 'Владелец (owner)', callback_data: 'adduser_role:owner' }],
                     [{ text: 'Наблюдатель (viewer)', callback_data: 'adduser_role:viewer' }],
                     [{ text: 'Участник (member)', callback_data: 'adduser_role:member' }]
                   ]
                 }
  end

  def adduser_role_callback_query(role)
    project_slug = session[:adduser_project_slug]
    username = session[:adduser_username]

    # Clean up session
    session.delete(:adduser_project_slug)
    session.delete(:adduser_username)

    edit_message :text, text: "Добавляем пользователя @#{username} в проект #{project_slug} с ролью #{role}..."

    add_user_to_project(project_slug, username, role)
  end

  def add_time(hours, *description)
    project = current_user.available_projects.find(session[:add_time_project_id]) || raise('Не указан проект')
    description = description.join(' ')
    project.time_shifts.create!(
      date: Time.zone.today,
      hours: hours.to_s.tr(',', '.').to_f,
      description: description,
      user: current_user
    )

    respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
  end

  def new_project_slug_input(slug, *)
    if slug.blank?
      respond_with :message, text: 'Slug не может быть пустым. Укажите slug для нового проекта:'
      return
    end

    project = current_user.projects.create!(name: slug, slug: slug)
    respond_with :message, text: "Создан проект `#{project.slug}`"
  rescue ActiveRecord::RecordInvalid => e
    respond_with :message, text: "Ошибка создания проекта: #{e.message}"
  end
end
