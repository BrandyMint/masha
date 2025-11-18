# frozen_string_literal: true

class RateCommand < BaseCommand
  provides_context_methods(:awaiting_rate_amount)

  # Context method name constants (for save_context calls)
  CONTEXT_AWAITING_RATE_AMOUNT = :awaiting_rate_amount

  def call(data = nil, *)
    return handle_rate_command(data) if data

    # Если нет аргументов, покажем интерактивное меню
    show_interactive_menu
  end

  # ==================== Context Methods (Public) ====================

  def awaiting_rate_amount(*amount_parts)
    amount_text = amount_parts.join(' ')

    # Проверка на отмену
    if cancel_input?(amount_text)
      clear_rate_context
      return respond_with :message, text: t('telegram.commands.rate.menu.operation_cancelled')
    end

    # Получаем данные из контекста
    context_data = session[CONTEXT_AWAITING_RATE_AMOUNT]
    return respond_with :message, text: t('telegram.commands.rate.unknown_error') unless context_data

    slug = context_data['project_slug']
    user_id = context_data['user_id']
    currency = context_data['currency']

    project = find_project(slug)
    target_user = User.find_by(id: user_id)

    unless project && target_user
      clear_rate_context
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    unless can_manage_project_rates?(project)
      clear_rate_context
      return respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
    end

    # Валидация суммы
    hourly_rate = amount_text.tr(',', '.').to_f
    return respond_with :message, text: t('telegram.commands.rate.menu.invalid_amount_input') if hourly_rate <= 0

    # Создание или обновление ставки
    member_rate = MemberRate.find_or_initialize_by(project: project, user: target_user)
    member_rate.hourly_rate = hourly_rate
    member_rate.currency = currency

    if member_rate.save
      clear_rate_context
      username = target_user.telegram_user&.telegram_nick || target_user.id.to_s
      respond_with :message,
                   text: t('telegram.commands.rate.menu.amount_saved',
                           username: username,
                           amount: hourly_rate,
                           currency: currency)
    else
      respond_with :message,
                   text: t('telegram.commands.rate.save_error',
                           errors: member_rate.errors.full_messages.join(', '))
    end
  end

  # ==================== Callback Query Methods ====================

  def rate_select_project_callback_query(slug)
    unless slug
      Bugsnag.notify(RuntimeError.new('rate_select_project_callback_query called without slug'))
      safe_answer_callback_query('❌ Ошибка: не передан slug проекта', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    project = find_project(slug)
    unless project
      safe_answer_callback_query('❌ Проект не найден', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.project_not_found_simple', project_name: slug)
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
    end

    safe_answer_callback_query
    show_project_menu(project)
  end

  def rate_view_list_callback_query(slug)
    unless slug
      Bugsnag.notify(RuntimeError.new('rate_view_list_callback_query called without slug'))
      safe_answer_callback_query('❌ Ошибка: не передан slug проекта', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    project = find_project(slug)
    unless project
      safe_answer_callback_query('❌ Проект не найден', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.project_not_found_simple', project_name: slug)
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_view_rates')
    end

    safe_answer_callback_query
    respond_with :message, text: format_project_rates_list(project)
  end

  def rate_set_rate_callback_query(slug)
    unless slug
      Bugsnag.notify(RuntimeError.new('rate_set_rate_callback_query called without slug'))
      safe_answer_callback_query('❌ Ошибка: не передан slug проекта', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    project = find_project(slug)
    unless project
      safe_answer_callback_query('❌ Проект не найден', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.project_not_found_simple', project_name: slug)
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
    end

    safe_answer_callback_query
    show_members_menu(project)
  end

  def rate_select_member_callback_query(data)
    unless data
      Bugsnag.notify(RuntimeError.new('rate_select_member_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    slug, user_id = data.split(',')
    project = find_project(slug)
    target_user = User.find_by(id: user_id)

    unless project && target_user
      safe_answer_callback_query('❌ Ошибка данных', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
    end

    safe_answer_callback_query
    show_currency_selection(project, target_user)
  end

  def rate_select_currency_callback_query(data)
    unless data
      Bugsnag.notify(RuntimeError.new('rate_select_currency_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    slug, user_id, currency = data.split(',')
    project = find_project(slug)
    target_user = User.find_by(id: user_id)

    unless project && target_user && MemberRate::CURRENCIES.include?(currency)
      safe_answer_callback_query('❌ Ошибка данных', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_owner_only')
    end

    # Сохраняем контекст для следующего шага
    save_context CONTEXT_AWAITING_RATE_AMOUNT
    session[CONTEXT_AWAITING_RATE_AMOUNT] = {
      'project_slug' => slug,
      'user_id' => user_id,
      'currency' => currency
    }

    username = target_user.telegram_user&.telegram_nick || target_user.id.to_s
    safe_answer_callback_query
    respond_with :message,
                 text: t('telegram.commands.rate.menu.enter_amount',
                         username: username,
                         currency: currency)
  end

  def rate_remove_callback_query(data)
    unless data
      Bugsnag.notify(RuntimeError.new('rate_remove_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    slug, user_id = data.split(',')
    project = find_project(slug)
    target_user = User.find_by(id: user_id)

    unless project && target_user
      safe_answer_callback_query('❌ Ошибка данных', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.unknown_error')
    end

    unless can_manage_project_rates?(project)
      safe_answer_callback_query('❌ Нет доступа', show_alert: true)
      return respond_with :message, text: t('telegram.commands.rate.access_denied_remove_rates')
    end

    member_rate = MemberRate.find_by(project: project, user: target_user)
    unless member_rate
      username = target_user.telegram_user&.telegram_nick || target_user.id.to_s
      safe_answer_callback_query('❌ Ставка не установлена', show_alert: true)
      return respond_with :message,
                          text: t('telegram.commands.rate.no_rate_set',
                                  username: username,
                                  project_name: project.slug)
    end

    if member_rate.destroy
      username = target_user.telegram_user&.telegram_nick || target_user.id.to_s
      safe_answer_callback_query('✅ Ставка удалена')
      respond_with :message,
                   text: t('telegram.commands.rate.menu.rate_removed',
                           username: username,
                           project_name: project.slug)
    else
      safe_answer_callback_query('❌ Ошибка удаления', show_alert: true)
      respond_with :message, text: t('telegram.commands.rate.remove_error')
    end
  end

  def rate_back_callback_query(slug)
    if slug.present?
      project = find_project(slug)
      if project
        safe_answer_callback_query
        return show_project_menu(project)
      end
    end

    safe_answer_callback_query
    show_interactive_menu
  end

  def rate_cancel_callback_query(_data = nil)
    clear_rate_context
    safe_answer_callback_query
    respond_with :message, text: t('telegram.commands.rate.menu.operation_cancelled')
  end

  private

  # ==================== Helper Methods ====================

  def show_interactive_menu
    projects = owned_projects

    return respond_with :message, text: t('telegram.commands.rate.menu.no_owned_projects') if projects.empty?

    # Single project optimization
    return show_project_menu(projects.first) if projects.count == 1

    # Build project selection buttons
    buttons = []
    project_buttons = projects.map do |project|
      {
        text: project.slug.truncate(20, omission: '...'),
        callback_data: "rate_select_project:#{project.slug}"
      }
    end

    project_buttons.each_slice(2) { |row| buttons << row }
    buttons << [{ text: t('telegram.commands.rate.menu.close'), callback_data: 'rate_cancel:' }]

    respond_with :message,
                 text: t('telegram.commands.rate.menu.select_project'),
                 reply_markup: { inline_keyboard: buttons }
  end

  def show_project_menu(project)
    buttons = [
      [{ text: t('telegram.commands.rate.menu.view_rates'), callback_data: "rate_view_list:#{project.slug}" }],
      [{ text: t('telegram.commands.rate.menu.set_rate'), callback_data: "rate_set_rate:#{project.slug}" }],
      [{ text: t('telegram.commands.rate.menu.back'), callback_data: 'rate_back:' }]
    ]

    respond_with :message,
                 text: t('telegram.commands.rate.menu.project_menu_title', project_name: project.slug),
                 reply_markup: { inline_keyboard: buttons }
  end

  def show_members_menu(project)
    members = project.users.includes(:telegram_user)

    return respond_with :message, text: t('telegram.commands.rate.menu.no_members') if members.empty?

    # Получаем существующие ставки для проекта
    rates = project.member_rates.includes(:user).index_by(&:user_id)

    buttons = []
    members.each do |user|
      rate = rates[user.id]
      rate_text = if rate
                    t('telegram.commands.rate.menu.current_rate',
                      rate: rate.rate_with_currency)
                  else
                    t('telegram.commands.rate.menu.no_rate')
                  end
      username = user.telegram_user&.telegram_nick || user.id.to_s

      member_row = [
        {
          text: "#{username}#{rate_text}",
          callback_data: "rate_select_member:#{project.slug},#{user.id}"
        }
      ]

      # Добавляем кнопку удаления если ставка установлена
      if rate
        member_row << {
          text: '🗑️',
          callback_data: "rate_remove:#{project.slug},#{user.id}"
        }
      end

      buttons << member_row
    end

    buttons << [{ text: t('telegram.commands.rate.menu.back'), callback_data: "rate_back:#{project.slug}" }]

    respond_with :message,
                 text: t('telegram.commands.rate.menu.select_member'),
                 reply_markup: { inline_keyboard: buttons }
  end

  def show_currency_selection(project, user)
    username = user.telegram_user&.telegram_nick || user.id.to_s
    buttons = MemberRate::CURRENCIES.map do |currency|
      {
        text: currency,
        callback_data: "rate_select_currency:#{project.slug},#{user.id},#{currency}"
      }
    end

    buttons_rows = buttons.each_slice(3).to_a
    buttons_rows << [{ text: t('telegram.commands.rate.menu.back'), callback_data: "rate_set_rate:#{project.slug}" }]

    respond_with :message,
                 text: t('telegram.commands.rate.menu.select_currency', username: username),
                 reply_markup: { inline_keyboard: buttons_rows }
  end

  def owned_projects
    current_user.available_projects.alive.joins(:memberships).where(
      memberships: { user: current_user, role_cd: Membership.roles[:owner] }
    ).distinct
  end

  def cancel_input?(text)
    return false if text.blank?

    text.strip.casecmp('cancel').zero?
  end

  def clear_rate_context
    session.delete(CONTEXT_AWAITING_RATE_AMOUNT)
  end

  # ==================== Original Text-based Command Methods ====================

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
                           project_name: project.slug,
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
                           project_name: project.slug)
      return
    end

    if member_rate.destroy
      respond_with :message,
                   text: t('telegram.commands.rate.rate_removed_successfully',
                           username: username,
                           project_name: project.slug)
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
    project.memberships.owners.exists?(user: current_user)
  end

  def find_user_by_username(username)
    username = username.delete('@')
    User.joins(:telegram_user).find_by(telegram_users: { username: username })
  end

  def format_rate_success(project, user, member_rate)
    [
      t('telegram.commands.rate.success_title'),
      t('telegram.commands.rate.success_project', project_name: project.slug),
      t('telegram.commands.rate.success_member', username: user.telegram_user.username),
      t('telegram.commands.rate.success_amount', amount: member_rate.hourly_rate, currency: member_rate.currency),
      t('telegram.commands.rate.success_updated', timestamp: Time.current.strftime('%d.%m.%Y %H:%M'))
    ].join("\n")
  end

  def format_project_rates_list(project)
    rates = project.member_rates.includes(:user)
    text = [t('telegram.commands.rate.rates_list_title', project_name: project.slug), '']

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
