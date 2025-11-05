# frozen_string_literal: true

module Telegram
  module FormattingHelpers
    extend ActiveSupport::Concern

    # Public methods needed by BaseCommand
    def multiline(*args)
      args.flatten.map(&:to_s).join("\n")
    end

    # Public methods needed by BaseCommand
    def code(text)
      multiline '```', text, '```'
    end

    # Public methods needed by BaseCommand
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
        '/rate {project} {username} {amount} [currency] - Установить почасовую ставку (только для владельцев)',
        '/rate list {project} - Посмотреть ставки проекта (только для владельцев)',
        '/rate remove {project} {username} - Удалить ставку (только для владельцев)',
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
      end

      multiline(commands)
    end
  end
end
