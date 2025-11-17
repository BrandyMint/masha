# frozen_string_literal: true

class ProjectsCommand < BaseCommand
  provides_context_methods(
    :awaiting_project_name,
    :awaiting_rename_slug,
    :awaiting_client_name,
    :awaiting_client_delete_confirm,
    :awaiting_delete_confirm
  )

  # Context method name constants (for save_context calls)
  CONTEXT_AWAITING_PROJECT_NAME = :awaiting_project_name
  CONTEXT_AWAITING_RENAME_SLUG = :awaiting_rename_slug
  CONTEXT_AWAITING_CLIENT_NAME = :awaiting_client_name
  CONTEXT_AWAITING_CLIENT_DELETE_CONFIRM = :awaiting_client_delete_confirm
  CONTEXT_AWAITING_DELETE_CONFIRM = :awaiting_delete_confirm

  def call(*args)
    return respond_with :message, text: t('commands.projects.unauthorized') unless current_user

    if args.empty?
      show_projects_list
    else
      # Обратная совместимость со старым форматом
      handle_legacy_create_format(args)
    end
  end

  # Callback query methods - каждый тип callback имеет свой метод
  def projects_create_callback_query(_data = nil)
    start_project_creation
    safe_answer_callback_query
  end

  def projects_select_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_select_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    show_project_menu(data)
    safe_answer_callback_query
  end

  def projects_list_callback_query(_data = nil)
    show_projects_list
    safe_answer_callback_query
  end

  def projects_close_callback_query(_data = nil)
    # В callback_query контексте используем edit_message
    edit_message :text,
                 text: '📋 Меню проектов закрыто',
                 reply_markup: { inline_keyboard: [] }
  end

  def projects_rename_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    show_rename_menu(data)
    safe_answer_callback_query
  end

  def projects_rename_slug_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_rename_slug_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    start_rename_slug(data)
    safe_answer_callback_query
  end

  def projects_client_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_client_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    show_client_menu(data)
    safe_answer_callback_query
  end

  def projects_client_edit_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_client_edit_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    start_client_edit(data)
    safe_answer_callback_query
  end

  def projects_client_delete_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_client_delete_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    confirm_client_deletion(data)
    safe_answer_callback_query
  end

  def projects_client_delete_confirm_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_client_delete_confirm_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: данные не переданы', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    delete_client(data)
    safe_answer_callback_query('✅ Клиент удалён из проекта')
  end

  def projects_delete_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_delete_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    confirm_project_deletion(data)
    safe_answer_callback_query
  end

  def projects_delete_confirm_callback_query(data = nil)
    unless data
      Bugsnag.notify(RuntimeError.new('projects_delete_confirm_callback_query called without data'))
      safe_answer_callback_query('❌ Ошибка: не переданы данные', show_alert: true)
      return respond_with :message, text: 'Что-то странное..'
    end
    request_deletion_confirmation(data)
    safe_answer_callback_query('⚠️ Введите название проекта для подтверждения удаления')
  end

  # Context methods - обработка текстовых сообщений
  def awaiting_project_name(*slug_parts)
    slug = slug_parts.join('-').strip.downcase
    return respond_with :message, text: t('commands.projects.create.cancelled') if cancel_input?(slug)
    return respond_with :message, text: t('commands.projects.create.error', reason: 'Slug не может быть пустым') if slug.blank?
    return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(slug)

    # Проверка уникальности
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: slug) if Project.exists?(slug: slug)

    project = Project.new(slug: slug)
    if project.save
      Membership.create!(user: current_user, project: project, role: :owner)
      return respond_with :message, text: t('commands.projects.create.success', slug: project.slug)

      show_projects_list
    else
      respond_with :message, text: t('commands.projects.create.error', reason: project.errors.full_messages.join(', '))
    end
  end

  def awaiting_rename_slug(*slug_parts)
    new_slug = slug_parts.join(' ').strip
    return handle_cancel_input :rename_slug if cancel_input?(new_slug)

    current_slug = session[:current_project_slug]
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

    # Проверка уникальности
    if Project.where.not(id: project.id).exists?(slug: new_slug)
      return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
    end

    old_slug = project.slug
    unless project.update(slug: new_slug)
      return respond_with :message,
                          text: t('commands.projects.rename.error',
                                  reason: project.errors.full_messages.join(', '))
    end

    text = t('commands.projects.rename.success_slug', old_slug: old_slug, new_slug: new_slug)
    session.delete(:current_project_slug)
    respond_with :message, text: text
    show_project_menu(new_slug)
  end

  def awaiting_client_name(*name_parts)
    client_name = name_parts.join(' ').strip
    return handle_cancel_input :client_name if cancel_input?(client_name)

    current_slug = session[:current_project_slug]
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    return respond_with :message, text: t('commands.projects.client.error') if client_name.blank?
    return respond_with :message, text: t('commands.projects.client.error') if client_name.length > 255

    # Ищем или создаем клиента
    client = Client.find_or_create_by(user: current_user, name: client_name) do |c|
      c.key = client_name.parameterize
    end

    old_client = project.client&.name || t('commands.projects.menu.no_client')
    unless project.update(client: client)
      return respond_with :message,
                          text: t('commands.projects.client.error',
                                  reason: project.errors.full_messages.join(', '))
    end

    text = t('commands.projects.client.success', old_client: old_client, new_client: client_name)
    session.delete(:current_project_slug)
    respond_with :message, text: text
    show_client_menu(current_slug)
  end

  def awaiting_client_delete_confirm(*parts)
    confirmation = parts.join(' ').strip
    return handle_cancel_input :client_delete if cancel_input?(confirmation)

    # Пользователь может подтвердить любым сообщением кроме "cancel"
    current_slug = session[:current_project_slug]
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    if project.update(client: nil)
      respond_with :message, text: t('commands.projects.client.delete_success')
      session.delete(:current_project_slug)
      show_client_menu(current_slug)
    else
      respond_with :message, text: t('commands.projects.client.error', reason: project.errors.full_messages.join(', '))
    end
  end

  def awaiting_delete_confirm(*parts)
    confirmation = parts.join(' ').strip
    return handle_cancel_input :delete if cancel_input?(confirmation)

    current_slug = session[:current_project_slug]
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    # Проверяем что пользователь ввел slug проекта
    if confirmation != project.slug
      respond_with :message, text: t('commands.projects.delete.slug_mismatch')
      show_project_menu(current_slug)
      return
    end

    # Удаляем проект - Rails автоматически удалит связанные данные (invites, time_shifts, memberships, member_rates)
    project_slug = project.slug
    project.destroy
    session.delete(:current_project_slug)
    respond_with :message, text: t('commands.projects.delete.success', slug: project_slug)
    show_projects_list
  end

  private

  def cancel_input?(text)
    text.downcase == 'cancel'
  end

  def handle_cancel_input(context_type)
    current_slug = session[:current_project_slug]
    session.delete(:current_project_slug)
    session.delete(:new_project_title)
    session.delete(:suggested_slug)

    case context_type
    when :rename_slug
      respond_with :message, text: t('commands.projects.rename.cancelled')
      show_project_menu(current_slug)
    when :client_name, :client_delete
      respond_with :message, text: t('commands.projects.client.cancelled')
      show_client_menu(current_slug)
    when :delete
      respond_with :message, text: t('commands.projects.delete.cancelled')
      show_project_menu(current_slug)
    end
  end

  def show_projects_list
    projects = current_user.projects.active.alphabetically.limit(30)

    buttons = []
    # Кнопка "Добавить проект" - занимает всю ширину
    buttons << [{ text: t('commands.projects.add_button'), callback_data: 'projects_create:' }]

    # Группируем проекты по 3 в ряд
    project_buttons = projects.map do |project|
      {
        text: project.slug.truncate(15, omission: '...'),
        callback_data: "projects_select:#{project.slug}"
      }
    end

    # Добавляем кнопки проектов группами по 3
    project_buttons.each_slice(3) do |row|
      buttons << row
    end

    # Кнопка "Закрыть" - отдельной строкой внизу
    buttons << [{ text: t('commands.projects.close_button'), callback_data: 'projects_close:' }]
    respond_with :message, text: t('commands.projects.title'), reply_markup: {
      inline_keyboard: buttons
    }
  end

  def start_project_creation
    save_context(CONTEXT_AWAITING_PROJECT_NAME)
    respond_with :message, text: t('commands.projects.create.enter_name')
  end

  def show_project_menu(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project

    can_manage = project.can_be_managed_by?(current_user)

    client_text = project.client&.name || t('commands.projects.menu.no_client')
    menu_text = t('commands.projects.menu.title',
                  slug: project.slug,
                  client: client_text)

    buttons = if can_manage
                [
                  [{ text: t('commands.projects.menu.rename_button'), callback_data: "projects_rename:#{slug}" }],
                  [{ text: t('commands.projects.menu.client_button'), callback_data: "projects_client:#{slug}" }],
                  [{ text: t('commands.projects.menu.delete_button'), callback_data: "projects_delete:#{slug}" }],
                  [{ text: t('commands.projects.menu.back_button'), callback_data: 'projects_list:' }]
                ]
              else
                [
                  [{ text: t('commands.projects.menu.owner_only') }],
                  [{ text: t('commands.projects.menu.back_button'), callback_data: 'projects_list:' }]
                ]
              end

    respond_with :message, text: menu_text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def show_rename_menu(slug)
    # Теперь переименование работает только по slug, поэтому сразу вызываем start_rename_slug
    start_rename_slug(slug)
  end

  def start_rename_slug(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    session[:current_project_slug] = slug
    save_context CONTEXT_AWAITING_RENAME_SLUG

    text = t('commands.projects.rename.enter_slug',
             current_slug: project.slug)
    respond_with :message, text: text
  end

  def start_client_edit(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    session[:current_project_slug] = slug
    save_context CONTEXT_AWAITING_CLIENT_NAME

    current_client = project.client&.name || t('commands.projects.menu.no_client')
    text = t('commands.projects.client.enter_name',
             current_client: current_client)
    respond_with :message, text: text
  end

  def confirm_client_deletion(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    return show_client_menu(slug) unless project.client

    session[:current_project_slug] = slug
    save_context CONTEXT_AWAITING_CLIENT_DELETE_CONFIRM

    text = t('commands.projects.client.confirm_delete',
             client_name: project.client.name)
    buttons = [
      [{ text: t('commands.projects.client.delete_confirm_yes'), callback_data: "projects_client_delete_confirm:#{slug}" }],
      [{ text: t('commands.projects.client.delete_cancel'), callback_data: "projects_client:#{slug}" }]
    ]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def confirm_project_deletion(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    session[:current_project_slug] = slug
    stats = project.deletion_stats

    text = t('commands.projects.delete.confirm_first',
             slug: project.slug,
             time_shifts: stats[:time_shifts_count],
             memberships: stats[:memberships_count],
             invites: stats[:invites_count])

    buttons = [
      [{ text: t('commands.projects.delete.confirm_yes'), callback_data: "projects_delete_confirm:#{slug}" }],
      [{ text: t('commands.projects.delete.confirm_cancel'), callback_data: "projects_select:#{slug}" }]
    ]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def request_deletion_confirmation(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    session[:current_project_slug] = slug
    save_context CONTEXT_AWAITING_DELETE_CONFIRM

    text = t('commands.projects.delete.confirm_final',
             slug: project.slug)
    respond_with :message, text: text
  end

  def show_client_menu(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    current_client = project.client&.name || t('commands.projects.menu.no_client')
    text = t('commands.projects.client.menu_title',
             project_slug: project.slug,
             client_name: current_client)

    buttons = [
      [{ text: t('commands.projects.client.edit_button'), callback_data: "projects_client_edit:#{slug}" }]
    ]

    # Кнопка удаления клиента только если клиент установлен
    buttons << [{ text: t('commands.projects.client.delete_button'), callback_data: "projects_client_delete:#{slug}" }] if project.client

    buttons << [{ text: t('commands.projects.menu.back_button'), callback_data: "projects_select:#{slug}" }]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def handle_legacy_create_format(args)
    # Обратная совместимость: /projects create slug или /projects create
    if args[0] == 'create'
      if args[1]
        # Явное создание: /projects create my-slug
        create_project_legacy(args[1])
      else
        # Интерактивное создание: /projects create
        start_project_creation
      end
    else
      # Неизвестное действие
      respond_with :message, text: t('commands.projects.unknown_action')
    end
  end

  def create_project_legacy(slug)
    # Проверка авторизации
    return respond_with :message, text: t('commands.projects.unauthorized') unless current_user

    # Валидация входных данных
    return respond_with :message, text: t('commands.projects.create.error', reason: 'Slug не может быть пустым') if slug.blank?
    return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(slug)

    # Проверка уникальности slug
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: slug) if Project.exists?(slug: slug)

    # Создаем проект только с slug
    project = Project.new(slug: slug)
    if project.save
      Membership.create(user: current_user, project: project, role: :owner)
      respond_with :message, text: t('commands.projects.create.success',
                                     slug: project.slug)
    else
      respond_with :message, text: t('commands.projects.create.error',
                                     reason: project.errors.full_messages.join(', '))
    end
  end

  def delete_client(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project&.can_be_managed_by?(current_user)

    if project.update(client: nil)
      respond_with :message, text: t('commands.projects.client.delete_success')
      show_client_menu(slug)
    else
      show_error_message(t('commands.projects.client.delete_error', reason: project.errors.full_messages.join(', ')))
    end
  end

  def show_error_message(message)
    respond_with :message, text: message
  end

  def invalid_slug?(slug)
    slug.blank? || slug.length > 15 || slug.match?(/[^a-z0-9-]/) || slug.match?(/^-|-$/)
  end
end
