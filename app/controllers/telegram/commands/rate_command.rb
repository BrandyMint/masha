# frozen_string_literal: true

module Telegram
  module Commands
    class RateCommand < BaseCommand
      def call(data = nil, *)
        return handle_rate_command(data) if data

        # Если нет аргументов, покажем справку
        show_rate_help
      end

      private

      def handle_rate_command(args)
        args = args.split if args.is_a?(String)
        command = args[1]&.downcase

        case command
        when 'list'
          handle_list(args[2])
        when 'remove'
          handle_remove(args[2], args[3])
        when nil
          show_rate_help
        else
          # Попытка установить ставку в формате /rate project username amount currency
          handle_set_rate(args[1], args[2], args[3], args[4])
        end
      end

      def handle_set_rate(project_name, username, amount, currency)
        # Валидация аргументов
        unless project_name && username && amount
          respond_with :message, text: rate_usage_error
          return
        end

        # Поиск проекта
        project = find_project(project_name)
        unless project
          respond_with :message, text: "❌ Проект '#{project_name}' не найден.\nДоступные проекты: #{current_user.available_projects.alive.pluck(:slug).join(', ')}"
          return
        end

        # Проверка прав доступа
        unless can_manage_project_rates?(project)
          respond_with :message, text: "❌ Ошибка доступа!\nТолько владелец проекта может устанавливать ставки участников."
          return
        end

        # Поиск пользователя
        target_user = find_user_by_username(username)
        unless target_user
          respond_with :message, text: "❌ Пользователь @#{username} не найден в системе."
          return
        end

        # Проверка, что пользователь участник проекта
        unless project.users.include?(target_user)
          respond_with :message, text: "❌ Участник @#{username} не найден в проекте '#{project.name}'.\n💡 Проверьте список участников: /rate list #{project_name}"
          return
        end

        # Валидация суммы
        hourly_rate = amount.to_s.tr(',', '.').to_f
        if hourly_rate <= 0
          respond_with :message, text: "❌ Неверная сумма: #{amount}. Сумма должна быть положительным числом."
          return
        end

        # Валидация валюты
        currency ||= 'RUB'
        unless MemberRate::CURRENCIES.include?(currency.upcase)
          respond_with :message, text: "❌ Неверная валюта: #{currency}. Доступные валюты: #{MemberRate::CURRENCIES.join(', ')}"
          return
        end

        # Создание или обновление ставки
        member_rate = MemberRate.find_or_initialize_by(project: project, user: target_user)
        member_rate.hourly_rate = hourly_rate
        member_rate.currency = currency.upcase

        if member_rate.save
          respond_with :message, text: format_rate_success(project, target_user, member_rate)
        else
          respond_with :message, text: "❌ Ошибка сохранения ставки: #{member_rate.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        Rails.logger.error "Error in RateCommand: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        respond_with :message, text: "❌ Произошла ошибка. Попробуйте еще раз."
      end

      def handle_list(project_name)
        unless project_name
          respond_with :message, text: "❌ Укажите название проекта: /rate list project_name"
          return
        end

        project = find_project(project_name)
        unless project
          respond_with :message, text: "❌ Проект '#{project_name}' не найден."
          return
        end

        unless can_manage_project_rates?(project)
          respond_with :message, text: "❌ Ошибка доступа!\nТолько владелец проекта может просматривать ставки."
          return
        end

        respond_with :message, text: format_project_rates_list(project)
      end

      def handle_remove(project_name, username)
        unless project_name && username
          respond_with :message, text: "❌ Укажите проект и пользователя: /rate remove project_name @username"
          return
        end

        project = find_project(project_name)
        unless project
          respond_with :message, text: "❌ Проект '#{project_name}' не найден."
          return
        end

        unless can_manage_project_rates?(project)
          respond_with :message, text: "❌ Ошибка доступа!\nТолько владелец проекта может удалять ставки."
          return
        end

        target_user = find_user_by_username(username)
        unless target_user
          respond_with :message, text: "❌ Пользователь @#{username} не найден."
          return
        end

        member_rate = MemberRate.find_by(project: project, user: target_user)
        unless member_rate
          respond_with :message, text: "❌ У пользователя @#{username} нет установленной ставки в проекте '#{project.name}'."
          return
        end

        if member_rate.destroy
          respond_with :message, text: "✅ Ставка @#{username} удалена из проекта '#{project.name}'."
        else
          respond_with :message, text: "❌ Ошибка удаления ставки."
        end
      end

      def show_rate_help
        help_text = multiline(
          '💰 Управление ставками участников проекта',
          '',
          '📝 Доступные команды:',
          '• /rate project @username amount currency - установить ставку',
          '• /rate list project_name - посмотреть все ставки проекта',
          '• /rate remove project_name @username - удалить ставку',
          '',
          '💡 Примеры:',
          '• /rate Website @john_doe 50 USD',
          '• /rate MobileApp @mary_smith 3000 RUB',
          '',
          '🔐 Только владелец проекта может управлять ставками.'
        )
        respond_with :message, text: help_text
      end

      def can_manage_project_rates?(project)
        project.memberships.where(user: current_user, role_cd: 0).exists? # owner role_cd = 0
      end

      def find_user_by_username(username)
        username = username.delete('@')
        User.joins(:telegram_user).find_by(telegram_users: { username: username })
      end

      def format_rate_success(project, user, member_rate)
        multiline(
          '✅ Ставка успешно установлена!',
          "📊 Проект: #{project.name}",
          "👤 Участник: @#{user.telegram_user.username}",
          "💰 Сумма: #{member_rate.hourly_rate} #{member_rate.currency}",
          "📅 Обновлено: #{Time.current.strftime('%d.%m.%Y %H:%M')}"
        )
      end

      def format_project_rates_list(project)
        rates = project.member_rates.includes(:user)
        text = multiline("💰 Ставки проекта \"#{project.name}\":", nil)

        project.users.each do |user|
          rate = rates.find { |r| r.user_id == user.id }
          rate_text = rate ? "#{rate.hourly_rate} #{rate.currency}" : "Не установлена"
          membership = project.memberships.find_by(user: user)
          role = membership&.role_cd == 0 ? ' (Владелец)' : ''
          username = user.telegram_user&.username || user.id.to_s

          text += "👤 @#{username}#{role}: #{rate_text}\n"
        end

        text
      end

      def rate_usage_error
        multiline(
          '❌ Неверный формат команды.',
          '',
          '📝 Правильные форматы:',
          '• /rate project @username amount [currency]',
          '• /rate list project_name',
          '• /rate remove project_name @username',
          '',
          '💡 Пример: /rate Website @john_doe 50 USD'
        )
      end
    end
  end
end