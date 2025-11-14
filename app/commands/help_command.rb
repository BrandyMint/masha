# frozen_string_literal: true

class HelpCommand < BaseCommand
  def call(*)
    respond_with :message, text: help_message
  end

  # Public methods needed by BaseCommand
  def help_message
    commands = [
      '/help - Эта подсказка',
      '/start - Начать работу с ботом',
      '/projects - Список проектов',
      '/add {project_slug} {hours} [description] - Отметить время',
      '/edit - Редактировать ранее добавленную запись времени',
      '/users - Показать пользователей текущего проекта',
      '/users add {project_slug} {username} [role] - Добавить пользователя в проект (роли: owner, viewer, member)',
      '/users help - Помощь по управлению пользователями',
      '/adduser {project_slug} {username} [role] - Добавить пользователя (устарела, используйте /users add)',
      '/client - Управление клиентами (добавление, редактирование, привязка проектов)',
      '/rate {project} {username} {amount} [currency] - Установить почасовую ставку (только для владельцев)',
      '/rate list {project} - Посмотреть ставки проекта (только для владельцев)',
      '/rate remove {project} {username} - Удалить ставку (только для владельцев)',
      '/report - Детальный отчёт по командам и проектам',
      '/day - Отчёт за день',
      '/summary {week|month} - Суммарный отчёт за период',
      '/hours [project_slug] - Все часы за последние 3 месяца',
      '',
      'Быстрое добавление времени:',
      '{hours} {project_slug} [description] - например: "2.5 myproject работал над фичей"',
      '{project_slug} {hours} [description] - например: "myproject 2.5 работал над фичей"'
    ]

    # Deprecated:
    # '/attach {projects_slug} - Указать проект этого чата',
    # '/reset - Сбросить сессию и контекст',
    # Add developer commands if user is developer
    if developer?
      commands << ''
      commands << '# Только для разработчика'
      commands << ''
      commands << '/users all - Список всех пользователей системы'
      commands << '/merge {email} {telegram_username} - Объединить аккаунты'
      commands << '/notify - Отправить уведомление всем пользователям'
    end

    # Add version at the end
    commands << ''
    commands << "Версия Маши: #{AppVersion}"
    commands << 'Исходный код: https://github.com/dapi/masha'
    commands << 'Поддержка: @pismenny'

    multiline(commands)
  end

  private

  # Public methods needed by BaseCommand
  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end
end
