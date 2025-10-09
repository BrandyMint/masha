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

  # Edit time shift callbacks
  def edit_select_time_shift_input(time_shift_id, *)
    time_shift = current_user.time_shifts.find_by(id: time_shift_id)

    unless time_shift
      respond_with :message, text: "Запись с ID #{time_shift_id} не найдена или недоступна"
      return
    end

    # Check permissions
    unless time_shift.updatable_by?(current_user)
      respond_with :message, text: 'У вас нет прав для редактирования этой записи'
      return
    end

    # Save time shift to session
    session[:edit_time_shift_id] = time_shift.id
    session[:edit_original_values] = {
      project_id: time_shift.project_id,
      hours: time_shift.hours,
      description: time_shift.description
    }

    save_context :edit_field_callback_query

    description = time_shift.description || '(нет)'
    text = "Запись ##{time_shift.id}:\n" \
           "Проект: #{time_shift.project.name}\n" \
           "Часы: #{time_shift.hours}\n" \
           "Описание: #{description}\n\n" \
           'Что хотите изменить?'

    respond_with :message,
                 text: text,
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: '📁 Проект', callback_data: 'edit_field:project' }],
                     [{ text: '⏰ Часы', callback_data: 'edit_field:hours' }],
                     [{ text: '📝 Описание', callback_data: 'edit_field:description' }],
                     [{ text: '❌ Отмена', callback_data: 'edit_field:cancel' }]
                   ]
                 }
  end

  def edit_field_callback_query(field)
    if field == 'cancel'
      session.delete(:edit_time_shift_id)
      session.delete(:edit_original_values)
      edit_message :text, text: 'Редактирование отменено'
      return
    end

    session[:edit_field] = field

    case field
    when 'project'
      edit_edit_project
    when 'hours'
      edit_edit_hours
    when 'description'
      edit_edit_description
    end
  end

  def edit_edit_project
    save_context :edit_project_callback_query
    projects = current_user.available_projects.alive

    edit_message :text,
                 text: 'Выберите новый проект:',
                 reply_markup: {
                   inline_keyboard: projects.map { |p| [{ text: p.name, callback_data: "edit_project:#{p.slug}" }] }
                 }
  end

  def edit_project_callback_query(project_slug)
    project = find_project(project_slug)

    unless project
      edit_message :text, text: 'Проект не найден'
      return
    end

    session[:edit_new_project_id] = project.id
    show_edit_confirmation
  end

  def edit_edit_hours
    save_context :edit_hours_input
    edit_message :text, text: 'Введите новое количество часов (например, 8 или 7.5):'
  end

  def edit_hours_input(hours_str, *)
    hours = hours_str.to_s.tr(',', '.').to_f

    if hours < 0.1
      respond_with :message, text: 'Количество часов должно быть не менее 0.1. Попробуйте еще раз:'
      return
    end

    session[:edit_new_hours] = hours
    show_edit_confirmation
  end

  def edit_edit_description
    save_context :edit_description_input
    edit_message :text, text: 'Введите новое описание (или отправьте "-" для пустого описания):'
  end

  def edit_description_input(description, *)
    description = nil if description == '-'

    if description && description.length > 1000
      respond_with :message, text: 'Описание не может быть длиннее 1000 символов. Попробуйте еще раз:'
      return
    end

    session[:edit_new_description] = description
    show_edit_confirmation
  end

  def show_edit_confirmation
    field = session[:edit_field]
    original = session[:edit_original_values]

    changes = []

    case field
    when 'project'
      new_project = Project.find(session[:edit_new_project_id])
      old_project = Project.find(original['project_id'])
      changes << "Проект: #{old_project.name} → #{new_project.name}"
    when 'hours'
      changes << "Часы: #{original['hours']} → #{session[:edit_new_hours]}"
    when 'description'
      old_desc = original['description'] || '(нет)'
      new_desc = session[:edit_new_description] || '(нет)'
      changes << "Описание: #{old_desc} → #{new_desc}"
    end

    save_context :edit_confirm_callback_query

    respond_with :message,
                 text: "Подтвердите изменения:\n\n#{changes.join("\n")}\n\nСохранить?",
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: '✅ Сохранить', callback_data: 'edit_confirm:save' }],
                     [{ text: '❌ Отмена', callback_data: 'edit_confirm:cancel' }]
                   ]
                 }
  end

  def edit_confirm_callback_query(action)
    if action == 'cancel'
      session.delete(:edit_time_shift_id)
      session.delete(:edit_original_values)
      session.delete(:edit_field)
      session.delete(:edit_new_project_id)
      session.delete(:edit_new_hours)
      session.delete(:edit_new_description)
      edit_message :text, text: 'Изменения отменены'
      return
    end

    time_shift_id = session[:edit_time_shift_id]
    time_shift = current_user.time_shifts.find(time_shift_id)
    field = session[:edit_field]

    case field
    when 'project'
      time_shift.update!(project_id: session[:edit_new_project_id])
    when 'hours'
      time_shift.update!(hours: session[:edit_new_hours])
    when 'description'
      time_shift.update!(description: session[:edit_new_description])
    end

    # Clean up session
    session.delete(:edit_time_shift_id)
    session.delete(:edit_original_values)
    session.delete(:edit_field)
    session.delete(:edit_new_project_id)
    session.delete(:edit_new_hours)
    session.delete(:edit_new_description)

    edit_message :text, text: "✅ Запись ##{time_shift.id} успешно обновлена!"
  rescue ActiveRecord::RecordInvalid => e
    edit_message :text, text: "Ошибка при сохранении: #{e.message}"
  end
end
