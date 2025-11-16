# frozen_string_literal: true

class EditCommand < BaseCommand
  include FormatHelpers

  provides_context_methods EDIT_SELECT_TIME_SHIFT_INPUT, EDIT_HOURS_INPUT, EDIT_DESCRIPTION_INPUT

  def call(*)
    show_time_shifts_list(1)
  end

  def show_time_shifts_list(page = 1)
    pagination_service = Telegram::Edit::PaginationService.new(session, current_user)
    result = pagination_service.get_paginated_time_shifts(page)

    if result[:time_shifts].empty?
      respond_with :message, text: 'У вас нет записей времени для редактирования'
      return
    end

    table_formatter = Telegram::Edit::TableFormatter.new
    text = table_formatter.format_time_shifts_table(result[:time_shifts], result[:pagination])

    pagination_service.save_pagination_context(result[:pagination])
    save_context BaseCommand::EDIT_SELECT_TIME_SHIFT_INPUT

    reply_markup = pagination_service.build_keyboard(result[:pagination])

    respond_with :message,
                 text: multiline(
                   text,
                   nil,
                   'Введите ID записи, которую хотите редактировать:'
                 ),
                 reply_markup:,
                 parse_mode: :Markdown
  end

  def edit_select_time_shift_input(time_shift_id, *)
    handle_selection(time_shift_id)
  end

  def edit_hours_input(hours_str, *)
    handle_hours_input(hours_str)
  end

  def edit_description_input(description, *)
    handle_description_input(description)
  end

  def handle_edit_pagination_callback(callback_data)
    service = Telegram::Edit::PaginationService.new(session, current_user)
    page = service.handle_callback(callback_data)
    return unless page

    show_time_shifts_list(page)
  end

  def edit_field_callback_query(field)
    handle_field_selection(field)
    safe_answer_callback_query
  end

  def edit_project_callback_query(project_slug)
    handle_project_selection(project_slug)
    safe_answer_callback_query
  end

  def edit_confirm_callback_query(action)
    if action == 'cancel'
      clear_telegram_session
      edit_message :text, text: 'Изменения отменены'
      safe_answer_callback_query('❌ Изменения отменены')
      return
    end

    time_operations_service = Telegram::TimeShiftOperationsService.new(current_user)
    time_shift = time_operations_service.edit_time_shift(telegram_session)
    unless time_shift
      handle_missing_time_shift
      safe_answer_callback_query('❌ Ошибка: запись не найдена', show_alert: true)
      return
    end

    data = telegram_session_data
    field = data['field']
    new_values = data['new_values']

    update_time_shift(time_shift, field, new_values)

    # Clean up session
    clear_telegram_session
    edit_message :text, text: "✅ Запись ##{time_shift.id} успешно обновлена!"
    safe_answer_callback_query('✅ Сохранено')
  rescue ActiveRecord::RecordInvalid => e
    Bugsnag.notify e
    edit_message :text, text: "Ошибка при сохранении: #{e.record.errors.full_messages.join(', ')}"
    safe_answer_callback_query('❌ Ошибка сохранения', show_alert: true)
  end

  private

  def handle_description_input(description)
    description = nil if description == '-'

    if description && description.length > 1000
      respond_with :message, text: 'Описание не может быть длиннее 1000 символов. Попробуйте еще раз:'
      return
    end

    tg_session = telegram_session
    tg_session[:new_values] = { description: description }
    self.telegram_session = tg_session
    show_confirmation
  end

  def handle_selection(time_shift_id)
    time_shift = find_time_shift(time_shift_id)

    unless time_shift
      respond_with :message, text: "Запись с ID #{time_shift_id} не найдена или недоступна"
      return
    end

    unless time_shift.updatable_by?(current_user)
      respond_with :message, text: 'У вас нет прав для редактирования этой записи'
      return
    end

    # Save time shift to session using TelegramSession
    TelegramSession.edit(
      time_shift_id: time_shift.id
    )

    # Контекст будет установлен через callback_query автоматически
    show_field_selection(time_shift)
  end

  def handle_field_selection(field)
    if field == 'cancel'
      clear_telegram_session
      edit_message :text, text: 'Редактирование отменено'
      return
    end

    telegram_session[:field] = field

    case field
    when 'project'
      show_project_selection
    when 'hours'
      show_hours_input
    when 'description'
      show_description_input
    end
  end

  def handle_hours_input(hours_str)
    hours = hours_str.to_s.tr(',', '.').to_f

    if hours < 0.1
      respond_with :message, text: 'Количество часов должно быть не менее 0.1. Попробуйте еще раз:'
      return
    end

    telegram_session[:new_values] = { hours: hours }
    show_confirmation
  end

  def handle_project_selection(project_slug)
    project_service = Telegram::ProjectService.new(user)
    project = project_service.find_project(project_slug)

    unless project
      edit_message :text, text: 'Проект не найден'
      return
    end

    telegram_session[:new_values] = { project_id: project.id }
    show_confirmation
  end

  def find_time_shift(time_shift_id)
    user.time_shifts.find_by(id: time_shift_id)
  end

  def find_project(project_slug)
    project_service = Telegram::ProjectService.new(user)
    project_service.find_project(project_slug)
  end

  def show_field_selection(time_shift)
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

  def show_project_selection
    time_operations_service = Telegram::TimeShiftOperationsService.new(current_user)
    time_shift = time_operations_service.edit_time_shift(telegram_session)
    return unless time_shift

    # Контекст будет установлен через callback_query автоматически
    projects = current_user.available_projects.alive

    text = "Выберите новый проект (текущий: #{time_shift.project.name}):"

    inline_keyboard = projects.map do |p|
      project_name = p.id == time_shift.project_id ? "#{p.name} (текущий)" : p.name
      [{ text: project_name, callback_data: "edit_project:#{p.slug}" }]
    end

    edit_message :text,
                 text: text,
                 reply_markup: { inline_keyboard: inline_keyboard }
  end

  def show_hours_input
    save_context EDIT_HOURS_INPUT
    edit_message :text, text: 'Введите новое количество часов (например, 8 или 7.5):'
  end

  def show_description_input
    save_context EDIT_DESCRIPTION_INPUT
    edit_message :text, text: 'Введите новое описание (или отправьте "-" для пустого описания):'
  end

  def show_confirmation
    time_operations_service = Telegram::TimeShiftOperationsService.new(current_user)
    time_shift = time_operations_service.edit_time_shift(telegram_session)
    return unless time_shift

    data = telegram_session_data
    field = data['field']
    new_values = data['new_values']

    changes = build_changes_text(time_shift, field, new_values)

    # Контекст будет установлен через callback_query автоматически

    respond_with :message,
                 text: "Подтвердите изменения:\n\n#{changes.join("\n")}\n\nСохранить?",
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: '✅ Сохранить', callback_data: 'edit_confirm:save' }],
                     [{ text: '❌ Отмена', callback_data: 'edit_confirm:cancel' }]
                   ]
                 }
  end

  def update_time_shift(time_shift, field, new_values)
    case field
    when 'project'
      time_shift.update!(project_id: new_values['project_id'])
    when 'hours'
      time_shift.update!(hours: new_values['hours'])
    when 'description'
      time_shift.update!(description: new_values['description'])
    end
  end
end

# Построить текст изменений для подтверждения
def build_changes_text(time_shift, field, new_values)
  case field
  when 'project'
    new_project = current_user.find_project project_id new_values['project_id']
    return ['Ошибка: новый проект не найден'] unless new_project

    ["Проект: #{time_shift.project.name} → #{new_project.name}"]
  when 'hours'
    ["Часы: #{time_shift.hours} → #{new_values['hours']}"]
  when 'description'
    old_desc = time_shift.description || '(нет)'
    new_desc = new_values['description'] || '(нет)'
    ["Описание: #{old_desc} → #{new_desc}"]
  else
    ['Ошибка: неизвестное поле для редактирования']
  end
end
