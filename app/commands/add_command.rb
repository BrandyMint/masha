# frozen_string_literal: true

class AddCommand < BaseCommand
  provides_context_methods :add_time

  def call(project_slug = nil, hours = nil, *description)
    if project_slug.nil?
      show_project_selection
    elsif looks_like_time_format?(project_slug) && project_exists?(hours)
      # Проверяем может ли это формат time project_slug description
      # Формат: /add time project_slug description
      add_time_to_project(hours, project_slug, description.join(' '))
    else
      # Формат: /add project_slug time description
      add_time_to_project(project_slug, hours, description.join(' '))
    end
  end

  def select_project_callback_query(project_slug)
    save_context ADD_TIME
    project = find_project project_slug
    controller.telegram_session = TelegramSession.add_time(project_id: project.id)

    prompt_text = t('commands.add.project_selected_prompt', project: project.slug) +
                  "\n\n(или 'cancel' для отмены)"

    edit_message :text, text: prompt_text
    safe_answer_callback_query(t('commands.add.project_selected'))
  end

  def add_cancel_callback_query(_data = nil)
    controller.clear_telegram_session
    edit_message :text,
                 text: t('commands.add.cancelled'),
                 reply_markup: { inline_keyboard: [] }
    safe_answer_callback_query
  end

  def add_time(hours, *description)
    # Проверка на отмену операции
    if hours.to_s.downcase == 'cancel'
      controller.clear_telegram_session
      return respond_with :message, text: t('commands.add.cancelled')
    end

    data = controller.telegram_session_data
    project = current_user.available_projects.find(data['project_id']) || raise('Не указан проект')

    hours_float = hours.to_s.tr(',', '.').to_f
    if looks_like_time_format?(hours)
      description = description.join(' ')
      time_shift = project.time_shifts.create(
        date: Time.zone.today,
        hours: hours.to_s.tr(',', '.').to_f,
        description: description,
        user: current_user
      )
    else
      # Параметр не выглядит как время, это или текст или что-то другое. Нужно исправить и повторить ввод
      return respond_with :message, text: t('commands.add.broken_hours', hours: hours)
    end

    if time_shift.valid?
      controller.clear_telegram_session
      respond_with :message, text: t('commands.add.time_recorded', project: project.slug, hours: hours)
    else
      respond_with :message, text: t('commands.add.error_creating', errors: time_shift.errors.full_messages.join(', '))
    end
  end

  private

  def show_project_selection
    projects = current_user.available_projects.alive

    # Empty state - нет проектов
    if projects.empty?
      return respond_with :message,
                          text: t('commands.add.empty_state_title'),
                          reply_markup: {
                            inline_keyboard: [[
                              {
                                text: t('commands.add.empty_state_create_button'),
                                callback_data: 'projects_create:'
                              }
                            ]]
                          }
    end

    # Single project optimization - пропускаем выбор проекта
    return show_single_project_prompt(projects.first) if projects.one?

    # Обычное состояние - показываем проекты + кнопка отмены
    project_buttons = projects.map do |p|
      { text: p.slug, callback_data: "select_project:#{p.slug}" }
    end.each_slice(3).to_a

    # Добавляем кнопку отмены в отдельной строке
    project_buttons << [{ text: t('commands.projects.cancel_button'), callback_data: 'add_cancel:' }]

    respond_with :message,
                 text: t('commands.add.project_selection_title'),
                 reply_markup: {
                   resize_keyboard: true,
                   inline_keyboard: project_buttons
                 }
  end

  def show_single_project_prompt(project)
    save_context ADD_TIME
    controller.telegram_session = TelegramSession.add_time(project_id: project.id)

    respond_with :message, text: t('commands.add.single_project_selected', project: project.slug)
  end

  def add_time_to_project(project_slug, hours, description)
    project = find_project(project_slug)

    if project.present?
      time_shift = project.time_shifts.create(
        date: Time.zone.today,
        hours: hours.to_s.tr(',', '.').to_f,
        description: description,
        user: current_user
      )

      message = if time_shift.valid?
                  t('commands.add.time_recorded', project: project.slug, hours: hours)
                else
                  t('commands.add.error_creating', errors: time_shift.errors.full_messages.join(', '))
                end
    else
      available = current_user.available_projects.alive.pluck(:slug).join(', ')
      message = t('commands.add.project_not_found', project: project_slug, available: available)
    end

    respond_with :message, text: message
  end

  def looks_like_time_format?(str)
    return false unless str.is_a?(String)

    # Проверяем формат времени (как в TelegramTimeTracker)
    return false unless str.match?(/\A\d+([.,]\d+)?\z/)

    # Конвертируем и проверяем базовый диапазон
    hours = str.tr(',', '.').to_f
    hours.positive?
  end

  def project_exists?(project_slug)
    return false if project_slug.blank?

    current_user.available_projects.alive.exists?(slug: project_slug)
  end
end
