# frozen_string_literal: true

class RateCommand < BaseCommand
  def call(data = nil, *)
    return handle_rate_command(data) if data

    # Если нет аргументов, покажем справку
    show_rate_help
  end

  private

  def handle_rate_command(args)
    args = args.split if args.is_a?(String)
    command = args[0]&.downcase

    case command
    when 'list'
      handle_list(args[1])
    when 'remove'
      handle_remove(args[1], args[2])
    when nil
      show_rate_help
    else
      # Попытка установить ставку в формате /rate project username amount currency
      handle_set_rate(args[0], args[1], args[2], args[3])
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
      available_projects = current_user.available_projects.alive.pluck(:slug).join(', ')
      respond_with :message,
                   text: t('telegram.commands.rate.project_not_found',
                           project_name: project_name,
                           available_projects: available_projects)
      return
    end

    # Проверка прав доступа
    unless can_manage_project_rates?(project)
      respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
      return
    end

    # Поиск пользователя
    target_user = find_user_by_username(username)
    unless target_user
      respond_with :message, text: t('telegram.commands.rate.user_not_found', username: username)
      return
    end

    # Проверка, что пользователь участник проекта
    unless project.users.include?(target_user)
      respond_with :message,
                   text: t('telegram.commands.rate.member_not_found_in_project',
                           username: username,
                           project_name: project.name,
                           project_name_command: project_name)
      return
    end

    # Валидация суммы
    hourly_rate = amount.to_s.tr(',', '.').to_f
    if hourly_rate <= 0
      respond_with :message, text: t('telegram.commands.rate.invalid_amount', amount: amount)
      return
    end

    # Валидация валюты
    currency ||= 'RUB'
    unless MemberRate::CURRENCIES.include?(currency.upcase)
      respond_with :message,
                   text: t('telegram.commands.rate.invalid_currency',
                           currency: currency,
                           available_currencies: MemberRate::CURRENCIES.join(', '))
      return
    end

    # Создание или обновление ставки
    member_rate = MemberRate.find_or_initialize_by(project: project, user: target_user)
    member_rate.hourly_rate = hourly_rate
    member_rate.currency = currency.upcase

    if member_rate.save
      respond_with :message, text: format_rate_success(project, target_user, member_rate)
    else
      respond_with :message,
                   text: t('telegram.commands.rate.save_error',
                           errors: member_rate.errors.full_messages.join(', '))
    end
  end

  def handle_list(project_name)
    unless project_name
      respond_with :message, text: t('telegram.commands.rate.specify_project_for_list')
      return
    end

    project = find_project(project_name)
    unless project
      respond_with :message, text: t('telegram.commands.rate.project_not_found_simple', project_name: project_name)
      return
    end

    unless can_manage_project_rates?(project)
      respond_with :message, text: t('telegram.commands.rate.access_denied_view_rates')
      return
    end

    respond_with :message, text: format_project_rates_list(project)
  end

  def handle_remove(project_name, username)
    unless project_name && username
      respond_with :message, text: t('telegram.commands.rate.specify_project_and_user_for_remove')
      return
    end

    project = find_project(project_name)
    unless project
      respond_with :message, text: t('telegram.commands.rate.project_not_found_simple', project_name: project_name)
      return
    end

    unless can_manage_project_rates?(project)
      respond_with :message, text: t('telegram.commands.rate.access_denied_remove_rates')
      return
    end

    target_user = find_user_by_username(username)
    unless target_user
      respond_with :message, text: t('telegram.commands.rate.user_not_found_simple', username: username)
      return
    end

    member_rate = MemberRate.find_by(project: project, user: target_user)
    unless member_rate
      respond_with :message,
                   text: t('telegram.commands.rate.no_rate_set',
                           username: username,
                           project_name: project.name)
      return
    end

    if member_rate.destroy
      respond_with :message,
                   text: t('telegram.commands.rate.rate_removed_successfully',
                           username: username,
                           project_name: project.name)
    else
      respond_with :message, text: t('telegram.commands.rate.remove_error')
    end
  end

  def show_rate_help
    help_text = [
      t('telegram.commands.rate.help_title'),
      '',
      t('telegram.commands.rate.help_commands_title'),
      t('telegram.commands.rate.help_set_rate'),
      t('telegram.commands.rate.help_list_rates'),
      t('telegram.commands.rate.help_remove_rate'),
      '',
      t('telegram.commands.rate.help_examples_title'),
      t('telegram.commands.rate.help_example_1'),
      t('telegram.commands.rate.help_example_2'),
      '',
      t('telegram.commands.rate.help_access_note')
    ].join("\n")

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
    [
      t('telegram.commands.rate.success_title'),
      t('telegram.commands.rate.success_project', project_name: project.name),
      t('telegram.commands.rate.success_member', username: user.telegram_user.username),
      t('telegram.commands.rate.success_amount', amount: member_rate.hourly_rate, currency: member_rate.currency),
      t('telegram.commands.rate.success_updated', timestamp: Time.current.strftime('%d.%m.%Y %H:%M'))
    ].join("\n")
  end

  def format_project_rates_list(project)
    rates = project.member_rates.includes(:user)
    text = [t('telegram.commands.rate.rates_list_title', project_name: project.name), '']

    project.users.each do |user|
      rate = rates.find { |r| r.user_id == user.id }
      rate_text = rate ? "#{rate.hourly_rate} #{rate.currency}" : t('telegram.commands.rate.rate_not_set')
      membership = project.memberships.find_by(user: user)
      role = membership&.role_cd&.zero? ? t('telegram.commands.rate.owner_role') : ''
      username = user.telegram_user&.username || user.id.to_s

      text << "👤 @#{username}#{role}: #{rate_text}\n"
    end

    text.join
  end

  def rate_usage_error
    [
      t('telegram.commands.rate.usage_error_title'),
      '',
      t('telegram.commands.rate.usage_correct_formats'),
      t('telegram.commands.rate.usage_format_set'),
      t('telegram.commands.rate.usage_format_list'),
      t('telegram.commands.rate.usage_format_remove'),
      '',
      t('telegram.commands.rate.usage_example')
    ].join("\n")
  end
end