# frozen_string_literal: true

# Хелперы для работы с TelegramSession
module TelegramSessionHelpers
  extend ActiveSupport::Concern

  # Получить текущую сессию
  def telegram_session
    return nil unless session[:telegram_session]

    TelegramSession.from_h(session[:telegram_session])
  end

  # Установить сессию
  def telegram_session=(tg_session)
    if tg_session.nil?
      session.delete(:telegram_session)
    else
      session[:telegram_session] = tg_session.to_h
    end
  end

  # Очистить сессию
  def clear_telegram_session
    session.delete(:telegram_session)
  end

  # Получить данные сессии (для удобного доступа)
  def telegram_session_data
    telegram_session&.data || {}
  end

  # Получить текущую запись времени для редактирования
  def edit_time_shift
    return nil unless telegram_session&.type == :edit

    time_shift_id = telegram_session[:time_shift_id]
    current_user.time_shifts.includes(:project).find_by(id: time_shift_id)
  end

  # Построить текст изменений для подтверждения
  def build_changes_text(time_shift, field, new_values)
    case field
    when 'project'
      new_project = current_user.available_projects.find_by(id: new_values['project_id'])
      return ["Ошибка: новый проект не найден"] unless new_project

      ["Проект: #{time_shift.project.name} → #{new_project.name}"]
    when 'hours'
      ["Часы: #{time_shift.hours} → #{new_values['hours']}"]
    when 'description'
      old_desc = time_shift.description || '(нет)'
      new_desc = new_values['description'] || '(нет)'
      ["Описание: #{old_desc} → #{new_desc}"]
    else
      ["Ошибка: неизвестное поле для редактирования"]
    end
  end

  # Обработать отсутствующую запись времени
  def handle_missing_time_shift
    clear_telegram_session
    respond_with :message, text: 'Ошибка: исходная запись не найдена. Операция отменена.'
  end
end
