# frozen_string_literal: true

class TelegramTimeTracker
  include Telegram::Concerns::ValidationsConcern
  def initialize(telegram_user, text)
    @user = telegram_user.user
    @telegram_user = telegram_user
    @message_parts = text.is_a?(String) ? text.split : text
  end

  def parse_and_add
    return { error: 'Я не Алиса, мне нужна конкретика. Жми /help' } if @message_parts.length < 2

    result = parse_time_tracking_message
    return result if result[:error]

    if result[:hours] && result[:project_slug]
      message = add_time_entry(result[:project_slug], result[:hours], result[:description])

      # Добавляем подсказку если она есть
      message = "#{message}\n\n💡 #{result[:suggestion]}" if result[:suggestion]

      { success: true, message: message }
    else
      { error: 'Я не Алиса, мне нужна конкретика. Жми /help' }
    end
  end

  private

  def parse_time_tracking_message
    first_part = @message_parts[0]
    second_part = @message_parts[1]
    description = @message_parts[2..].join(' ') if @message_parts.length > 2

    result = determine_hours_and_project(first_part, second_part)
    return result if result[:error]

    { hours: result[:hours], project_slug: result[:project_slug], description: description }
  end

  def determine_hours_and_project(first_part, second_part)
    # Получаем контекст доступных проектов
    available_slugs = available_projects_slugs

    # Проверяем точное совпадение с проектами
    first_is_project = available_slugs.include?(first_part)
    second_is_project = available_slugs.include?(second_part)

    # Проверяем формат времени
    first_is_time = time_format?(first_part)
    second_is_time = time_format?(second_part)

    # Кейс 1: Проверяем время на допустимый диапазон
    first_hours_out_of_range = first_is_time && time_out_of_range?(first_part)
    second_hours_out_of_range = second_is_time && time_out_of_range?(second_part)

    if first_hours_out_of_range || second_hours_out_of_range
      bad_time = first_hours_out_of_range ? first_part : second_part
      return handle_time_out_of_range(bad_time)
    end

    # Кейс 2: Однозначное определение
    if first_is_time && second_is_project
      return { hours: first_part, project_slug: second_part }
    elsif first_is_project && second_is_time
      return { hours: second_part, project_slug: first_part }
    end

    # Кейс 3: Оба могут быть временем - запрос уточнения
    return handle_ambiguous_time(first_part, second_part) if first_is_time && second_is_time

    # Кейс 3: Оба могут быть проектами - предложение вариантов
    return handle_ambiguous_project(first_part, second_part) if first_is_project && second_is_project

    # Кейс 4: Один из них проект, другой не время
    if first_is_project
      return { error: "Второй параметр '#{second_part}' не похож на время. Используйте формат: 'project 2.5 описание'" }
    elsif second_is_project
      return { error: "Первый параметр '#{first_part}' не похож на время. Используйте формат: '2.5 project описание'" }
    end

    # Кейс 5: Пробуем найти проекты с опечатками
    first_project_fuzzy = find_project_fuzzy(first_part)
    second_project_fuzzy = find_project_fuzzy(second_part)

    if first_project_fuzzy && second_is_time
      return { hours: second_part, project_slug: first_project_fuzzy.slug,
               suggestion: "💡 Возможно вы имели в виду проект '#{first_project_fuzzy.slug}'?" }
    elsif second_project_fuzzy && first_is_time
      return { hours: first_part, project_slug: second_project_fuzzy.slug,
               suggestion: "💡 Возможно вы имели в виду проект '#{second_project_fuzzy.slug}'?" }
    end

    # Кейс 5b: Проверяем опечатки даже если вторая часть не время (но похожа на время)
    if first_project_fuzzy && numeric?(second_part)
      hours = second_part.to_s.tr(',', '.').to_f
      if hours >= 0.1 && hours <= 24
        return { hours: second_part, project_slug: first_project_fuzzy.slug,
                 suggestion: "💡 Возможно вы имели в виду проект '#{first_project_fuzzy.slug}'?" }
      end
    elsif second_project_fuzzy && numeric?(first_part)
      hours = first_part.to_s.tr(',', '.').to_f
      if hours >= 0.1 && hours <= 24
        return { hours: first_part, project_slug: second_project_fuzzy.slug,
                 suggestion: "💡 Возможно вы имели в виду проект '#{second_project_fuzzy.slug}'?" }
      end
    end

    # Кейс 6: Ничего не подошло - подробная ошибка
    handle_no_match(first_part, second_part)
  end

  def time_format?(str)
    return false unless str.is_a?(String)

    # Проверяем формат времени
    return false unless str.match?(/\A\d+([.,]\d+)?\z/)

    # Конвертируем и проверяем диапазон
    hours = str.tr(',', '.').to_f
    hours.positive? && hours <= 100.0 # Более широкая проверка, диапазон проверим отдельно
  end

  def handle_ambiguous_time(first_part, second_part)
    {
      error: multiline(
        '❓ Не понял. Вы имели в виду:',
        "• #{first_part} часа в каком проекте?",
        "• #{second_part} часа в каком проекте?",
        '',
        "Укажите проект: \"#{first_part} project\" или \"#{second_part} project\""
      )
    }
  end

  def handle_ambiguous_project(first_part, second_part)
    {
      error: multiline(
        '❓ Не понял. Вы имели в виду:',
        "• Проект '#{first_part}' сколько часов?",
        "• Проект '#{second_part}' сколько часов?",
        '',
        "Укажите время: \"2.5 #{first_part}\" или \"2.5 #{second_part}\""
      )
    }
  end

  def handle_no_match(first_part, second_part)
    # Проверяем может быть это время но с ошибкой
    if numeric?(first_part) || numeric?(second_part)
      time_part = numeric?(first_part) ? first_part : second_part
      project_part = numeric?(first_part) ? second_part : first_part

      if numeric?(time_part)
        hours = time_part.to_s.tr(',', '.').to_f
        if hours < 0.1
          return { error: "Слишком мало времени: #{hours}. Минимум 0.1 часа." }
        elsif hours > 24
          return { error: "Слишком много времени: #{hours}. Максимум 24 часа." }
        end
      end

      # Пробуем предложить похожие проекты
      similar_projects = find_similar_projects(project_part)
      if similar_projects.any?
        return {
          error: "Не найден проект '#{project_part}'. Возможно вы имели в виду: #{similar_projects.join(', ')}"
        }
      end

      # Время есть, но проект не найден
      return { error: "Не найден проект '#{project_part}'. Доступные проекты: #{available_projects_slugs.join(', ')}" }
    end

    available_projects = available_projects_slugs.join(', ')
    {
      error: multiline(
        '❌ Не удалось определить часы и проект.',
        '',
        "Вы ввели: '#{first_part}' '#{second_part}'",
        '',
        'Правильные форматы:',
        '• 2.5 project описание',
        '• project 2.5 описание',
        '',
        "Доступные проекты: #{available_projects}"
      )
    }
  end

  def time_out_of_range?(str)
    return false unless str.is_a?(String)

    hours = str.tr(',', '.').to_f
    hours < 0.1 || hours > 24.0
  end

  def handle_time_out_of_range(time_str)
    hours = time_str.tr(',', '.').to_f
    if hours < 0.1
      { error: "Слишком мало времени: #{hours}. Минимум 0.1 часа." }
    else
      { error: "Слишком много времени: #{hours}. Максимум 24 часа." }
    end
  end

  def multiline(*lines)
    lines.compact.join("\n")
  end

  def add_time_entry(project_slug, hours, description = nil)
    service = Telegram::TimeShiftOperationsService.new(@user)
    service.add_time_entry(project_slug, hours, description)
  end

  def find_project(key)
    project_service = Telegram::ProjectService.new(@user)
    project_service.find_project(key)
  end

  # Дополнительные методы для работы с проектами
  def find_project_fuzzy(slug)
    project_service = Telegram::ProjectService.new(@user)
    project_service.find_project_fuzzy(slug)
  end

  def available_projects_slugs
    project_service = Telegram::ProjectService.new(@user)
    project_service.available_projects_slugs
  end

  def find_similar_projects(slug)
    project_service = Telegram::ProjectService.new(@user)
    project_service.find_similar_projects(slug)
  end
end
