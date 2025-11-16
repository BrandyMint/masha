# frozen_string_literal: true

class HelpCommand < BaseCommand
  def call(*)
    respond_with :message, text: help_message
  end

  # Public methods needed by BaseCommand
  def help_message
    commands = [
      '📝 Быстрое добавление времени',
      'Отправьте просто сообщение в любом из форматов:',
      '• {hours} {project_slug} [description]',
      '  Например: "2.5 myproject работал над фичей"',
      '• {project_slug} {hours} [description]',
      '  Например: "myproject 2.5 работал над фичей"',
      '',
      '⚙️ Основные команды',
      '/help - Эта подсказка',
      '',
      '⏱️ Управление временем',
      '/add {project_slug} {hours} [description] - Отметить время',
      '/edit - Редактировать ранее добавленную запись',
      '',
      '📁 Проекты и пользователи',
      '/projects - Список проектов',
      '/users - Показать пользователей текущего проекта',
      '/users add {project_slug} {username} [role] - Добавить пользователя',
      '/users help - Помощь по управлению пользователями',
      '/client - Управление клиентами',
      '/rate {project} {username} {amount} [currency] - Установить ставку (владельцы)',
      '/rate list {project} - Посмотреть ставки (владельцы)',
      '/rate remove {project} {username} - Удалить ставку (владельцы)',
      '',
      '📊 Отчёты',
      '/report - Универсальные отчёты (подробности: /report help)',
      '/day - Отчёт за день (устарела, используйте /report today)',
      '/summary {week|month} - Отчёт за период (устарела, используйте /report)',
      '/hours [project_slug] - Часы за 3 месяца (устарела, используйте /report quarter)'
    ]

    # Add developer commands if user is developer
    if developer?
      commands << ''
      commands << '👨‍💻 Команды для разработчика'
      commands << '/users all - Список всех пользователей системы'
      commands << '/merge {email} {telegram_username} - Объединить аккаунты'
      commands << '/notify - Отправить уведомление всем пользователям'
      commands << '/test - Тестовая команда'
      commands << ''
      commands << '🔒 Скрытые команды'
      commands << '/start - Начать работу с ботом / авторизация'
      commands << '/attach {project_slug} - Указать проект этого чата'
      commands << '/reset - Сбросить сессию и контекст'
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
