# frozen_string_literal: true

class ProjectsCommand < BaseCommand
  # Shortcut for telegram command translations
  def t(key, **options)
    super("telegram.#{key}", **options)
  end
  provides_context_methods(
    :awaiting_project_name,
    :awaiting_rename_title,
    :awaiting_rename_slug,
    :awaiting_rename_both,
    :awaiting_rename_both_step_2,
    :awaiting_client_name,
    :awaiting_client_delete_confirm,
    :awaiting_delete_confirm
  )

  # Context constants
  CONTEXT_AWAITING_PROJECT_NAME = :awaiting_project_name
  CONTEXT_AWAITING_RENAME_TITLE = :awaiting_rename_title
  CONTEXT_AWAITING_RENAME_SLUG = :awaiting_rename_slug
  CONTEXT_AWAITING_RENAME_BOTH = :awaiting_rename_both
  CONTEXT_AWAITING_RENAME_BOTH_STEP_2 = :awaiting_rename_both_step_2
  CONTEXT_AWAITING_CLIENT_NAME = :awaiting_client_name
  CONTEXT_AWAITING_CLIENT_DELETE_CONFIRM = :awaiting_client_delete_confirm
  CONTEXT_AWAITING_DELETE_CONFIRM = :awaiting_delete_confirm
  CONTEXT_CURRENT_PROJECT = :current_project_slug
  CONTEXT_RENAME_ACTION = :rename_action
  CONTEXT_SUGGESTED_SLUG = :suggested_slug

  def call(*args)
    return respond_with :message, text: t('commands.projects.unauthorized') unless current_user

    if args.empty?
      show_projects_list
    else
      # Обратная совместимость со старым форматом
      handle_legacy_create_format(args)
    end
  end

  def projects_callback_query(data = nil)
    data ||= callback_data
    return unless data

    case data
    when 'projects:create'
      start_project_creation
    when /^projects:select:(.+)$/
      show_project_menu(Regexp.last_match(1))
    when 'projects:list'
      show_projects_list
    when /^projects:rename:(.+)$/
      show_rename_menu(Regexp.last_match(1))
    when /^projects:rename_title:(.+)$/
      start_rename_title(Regexp.last_match(1))
    when /^projects:rename_slug:(.+)$/
      start_rename_slug(Regexp.last_match(1))
    when /^projects:rename_both:(.+)$/
      start_rename_both(Regexp.last_match(1))
    when /^projects:rename_use_suggested:(.+):(.+)$/
      use_suggested_slug(Regexp.last_match(1), Regexp.last_match(2))
    when /^projects:client:(.+)$/
      show_client_menu(Regexp.last_match(1))
    when /^projects:client_edit:(.+)$/
      start_client_edit(Regexp.last_match(1))
    when /^projects:client_delete:(.+)$/
      confirm_client_deletion(Regexp.last_match(1))
    when /^projects:client_delete_confirm:(.+)$/
      delete_client(Regexp.last_match(1))
    when /^projects:delete:(.+)$/
      confirm_project_deletion(Regexp.last_match(1))
    when /^projects:delete_confirm:(.+)$/
      request_deletion_confirmation(Regexp.last_match(1))
    end
  end

  def callback_data
    controller.callback_query.data
  rescue StandardError
    nil
  end

  # Context methods - обработка текстовых сообщений
  def awaiting_project_name(*name_parts)
    name = name_parts.join(' ').strip
    return respond_with :message, text: t('commands.projects.create.cancelled') if cancel_input?(name)
    return respond_with :message, text: t('commands.projects.create.error', reason: 'Название не может быть пустым') if name.blank?

    if name.length > 100
      return respond_with :message,
                          text: t('commands.projects.create.error', reason: 'Название слишком длинное (макс 100)')
    end

    slug = Project.generate_unique_slug(name)
    unless slug
      return respond_with :message,
                          text: t('commands.projects.create.error', reason: 'Не удалось сгенерировать уникальный идентификатор')
    end

    project = Project.new(name: name, slug: slug)
    if project.save
      Membership.create(user: current_user, project: project, role: 'owner')
      respond_with :message, text: t('commands.projects.create.success', name: project.name, slug: project.slug)
      show_projects_list
    else
      respond_with :message, text: t('commands.projects.create.error', reason: project.errors.full_messages.join(', '))
    end
  end

  def awaiting_rename_title(*title_parts)
    new_title = title_parts.join(' ').strip
    return handle_cancel_input :rename_title if cancel_input?(new_title)
    return respond_with :message, text: t('commands.projects.rename.error') if new_title.blank?

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    old_name = project.name
    if project.update(name: new_title)
      text = t('commands.projects.rename.success_title', old_name: old_name, new_name: new_title)
      respond_with :message, text: text
      show_project_menu(current_slug)
    else
      respond_with :message, text: t('commands.projects.rename.error')
    end
  end

  def awaiting_rename_slug(*slug_parts)
    new_slug = slug_parts.join(' ').strip
    return handle_cancel_input :rename_slug if cancel_input?(new_slug)

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

    # Проверка уникальности
    if Project.where.not(id: project.id).exists?(slug: new_slug)
      return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
    end

    old_slug = project.slug
    if project.update(slug: new_slug)
      text = t('commands.projects.rename.success_slug', old_slug: old_slug, new_slug: new_slug)
      respond_with :message, text: text
      show_project_menu(new_slug)
    else
      respond_with :message, text: t('commands.projects.rename.error')
    end
  end

  def awaiting_rename_both(*title_parts)
    new_title = title_parts.join(' ').strip
    return handle_cancel_input :rename_both if cancel_input?(new_title)
    return respond_with :message, text: t('commands.projects.rename.error') if new_title.blank?

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    # Сохраняем новое название и просим slug
    save_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)
    save_context(CONTEXT_RENAME_ACTION, 'both')

    # Генерируем предложенный slug
    suggested_slug = Project.generate_unique_slug(new_title)
    save_context(CONTEXT_SUGGESTED_SLUG, suggested_slug)

    text = t('commands.projects.rename.enter_slug',
             current_slug: current_slug)
    text += "\nПредложенный (на основе названия): #{suggested_slug}\n\n⚠️ Нажмите кнопку ниже или введите свой вариант"

    buttons = [
      [{ text: t('commands.projects.rename.use_suggested'),
         callback_data: "projects:rename_use_suggested:#{current_slug}:#{suggested_slug}" }]
    ]

    respond_with :message, text: text,
                           reply_markup: { inline_keyboard: buttons }
  end

  def awaiting_rename_both_step_2(*slug_parts)
    new_slug = slug_parts.join(' ').strip
    return handle_cancel_input :rename_both if cancel_input?(new_slug)

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    new_title = from_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project && new_title

    return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

    # Проверка уникальности
    if Project.where.not(id: project.id).exists?(slug: new_slug)
      return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
    end

    update_project_both(project, new_title, new_slug)
  end

  def awaiting_client_name(*name_parts)
    client_name = name_parts.join(' ').strip
    return handle_cancel_input :client_name if cancel_input?(client_name)

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    return respond_with :message, text: t('commands.projects.client.error') if client_name.blank?
    return respond_with :message, text: t('commands.projects.client.error') if client_name.length > 255

    # Ищем или создаем клиента
    client = Client.find_or_create_by(user: current_user, name: client_name) do |c|
      c.key = client_name.parameterize
    end

    old_client = project.client&.name || t('commands.projects.menu.no_client')
    if project.update(client: client)
      text = t('commands.projects.client.success', old_client: old_client, new_client: client_name)
      respond_with :message, text: text
      show_client_menu(current_slug)
    else
      respond_with :message, text: t('commands.projects.client.error')
    end
  end

  def awaiting_client_delete_confirm(*parts)
    confirmation = parts.join(' ').strip
    return handle_cancel_input :client_delete if cancel_input?(confirmation)

    # Пользователь может подтвердить любым сообщением кроме "cancel"
    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    if project.update(client: nil)
      respond_with :message, text: t('commands.projects.client.delete_success')
      show_client_menu(current_slug)
    else
      respond_with :message, text: t('commands.projects.client.error')
    end
  end

  def awaiting_delete_confirm(*parts)
    confirmation = parts.join(' ').strip
    return handle_cancel_input :delete if cancel_input?(confirmation)

    current_slug = from_context(CONTEXT_CURRENT_PROJECT)
    project = current_user.projects.find_by(slug: current_slug)
    return show_projects_list unless project

    # Проверяем что пользователь ввел название проекта
    if confirmation != project.name
      respond_with :message, text: t('commands.projects.delete.name_mismatch')
      show_project_menu(current_slug)
      return
    end

    # Удаляем проект
    project_name = project.name
    project.destroy
    respond_with :message, text: t('commands.projects.delete.success', name: project_name)
    show_projects_list
  end

  private

  def cancel_input?(text)
    text.downcase == 'cancel'
  end

  def handle_cancel_input(context_type)
    case context_type
    when :rename_title, :rename_slug, :rename_both
      current_slug = from_context(CONTEXT_CURRENT_PROJECT)
      respond_with :message, text: t('commands.projects.rename.cancelled')
      show_project_menu(current_slug)
    when :client_name, :client_delete
      current_slug = from_context(CONTEXT_CURRENT_PROJECT)
      respond_with :message, text: t('commands.projects.client.cancelled')
      show_client_menu(current_slug)
    when :delete
      current_slug = from_context(CONTEXT_CURRENT_PROJECT)
      respond_with :message, text: t('commands.projects.delete.cancelled')
      show_project_menu(current_slug)
    end
  end

  def show_projects_list
    projects = current_user.projects.active.alphabetically.limit(30)

    # Формируем текст с заголовком
    text = t('commands.projects.title')

    # Если проектов нет, добавляем сообщение о пустом списке
    if projects.empty?
      text += "\n\nУ вас пока нет проектов."
    else
      # Добавляем список проектов в текст
      projects.each do |project|
        client_info = project.client ? " (#{project.client.name})" : ''
        text += "\n• #{project.name}#{client_info}"
      end
    end

    # Добавляем подсказку о создании проекта
    text += "\n\n💡 *Создать новый проект:* /projects create"

    buttons = []
    # Кнопка "Добавить проект" - занимает всю ширину
    buttons << [{ text: t('commands.projects.add_button'), callback_data: 'projects:create' }]

    # Группируем проекты по 3 в ряд
    project_buttons = projects.map do |project|
      {
        text: project.slug.truncate(15, omission: '...'),
        callback_data: "projects:select:#{project.slug}"
      }
    end

    # Добавляем кнопки проектов группами по 3
    project_buttons.each_slice(3) do |row|
      buttons << row
    end

    respond_with :message, text: text,
                           reply_markup: {
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
                  name: project.name,
                  slug: project.slug,
                  client: client_text)

    buttons = if can_manage
                [
                  [{ text: t('commands.projects.menu.rename_button'), callback_data: "projects:rename:#{slug}" }],
                  [{ text: t('commands.projects.menu.client_button'), callback_data: "projects:client:#{slug}" }],
                  [{ text: t('commands.projects.menu.delete_button'), callback_data: "projects:delete:#{slug}" }],
                  [{ text: t('commands.projects.menu.back_button'), callback_data: 'projects:list' }]
                ]
              else
                [
                  [{ text: t('commands.projects.menu.owner_only') }],
                  [{ text: t('commands.projects.menu.back_button'), callback_data: 'projects:list' }]
                ]
              end

    respond_with :message, text: menu_text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def show_rename_menu(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)

    menu_text = t('commands.projects.rename.title', name: project.name)
    buttons = [
      [{ text: t('commands.projects.rename.title_button'), callback_data: "projects:rename_title:#{slug}" }],
      [{ text: t('commands.projects.rename.slug_button'), callback_data: "projects:rename_slug:#{slug}" }],
      [{ text: t('commands.projects.rename.both_button'), callback_data: "projects:rename_both:#{slug}" }],
      [{ text: t('commands.projects.rename.cancel_button'), callback_data: "projects:select:#{slug}" }]
    ]

    respond_with :message, text: menu_text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def start_rename_title(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_RENAME_TITLE)

    text = t('commands.projects.rename.enter_title',
             current_name: project.name)
    respond_with :message, text: text
  end

  def start_rename_slug(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_RENAME_SLUG)

    text = t('commands.projects.rename.enter_slug',
             current_slug: project.slug)
    respond_with :message, text: text
  end

  def start_rename_both(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_RENAME_BOTH)

    text = t('commands.projects.rename.enter_title',
             current_name: project.name)
    respond_with :message, text: text
  end

  def start_client_edit(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_CLIENT_NAME)

    current_client = project.client&.name || t('commands.projects.menu.no_client')
    text = t('commands.projects.client.enter_name',
             current_client: current_client)
    respond_with :message, text: text
  end

  def confirm_client_deletion(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    return show_client_menu(slug) unless project.client

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_CLIENT_DELETE_CONFIRM)

    text = t('commands.projects.client.confirm_delete',
             client_name: project.client.name)
    buttons = [
      [{ text: t('commands.projects.client.delete_confirm_yes'), callback_data: "projects:client_delete_confirm:#{slug}" }],
      [{ text: t('commands.projects.client.delete_cancel'), callback_data: "projects:client:#{slug}" }]
    ]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def confirm_project_deletion(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    stats = project.deletion_stats

    text = t('commands.projects.delete.confirm_first',
             name: project.name,
             time_shifts: stats[:time_shifts_count],
             memberships: stats[:memberships_count],
             invites: stats[:invites_count])

    buttons = [
      [{ text: t('commands.projects.delete.confirm_yes'), callback_data: "projects:delete_confirm:#{slug}" }],
      [{ text: t('commands.projects.delete.confirm_cancel'), callback_data: "projects:select:#{slug}" }]
    ]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def request_deletion_confirmation(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)
    save_context(CONTEXT_AWAITING_DELETE_CONFIRM)

    text = t('commands.projects.delete.confirm_final',
             name: project.name)
    respond_with :message, text: text
  end

  def show_client_menu(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    save_context(CONTEXT_CURRENT_PROJECT, slug)

    current_client = project.client&.name || t('commands.projects.menu.no_client')
    text = t('commands.projects.client.menu_title',
             project_name: project.name,
             client_name: current_client)

    buttons = [
      [{ text: t('commands.projects.client.edit_button'), callback_data: "projects:client_edit:#{slug}" }]
    ]

    # Кнопка удаления клиента только если клиент установлен
    buttons << [{ text: t('commands.projects.client.delete_button'), callback_data: "projects:client_delete:#{slug}" }] if project.client

    buttons << [{ text: t('commands.projects.menu.back_button'), callback_data: "projects:select:#{slug}" }]

    respond_with :message, text: text,
                           reply_markup: {
                             inline_keyboard: buttons
                           }
  end

  def use_suggested_slug(slug, suggested_slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    # Получаем новое название из контекста (должно быть сохранено перед этим)
    new_name = from_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2)
    return show_projects_list unless new_name

    update_project_both(project, new_name, suggested_slug)
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

    # Для совместимости со старым форматом
    project = Project.new(name: slug, slug: slug)
    if project.save
      Membership.create(user: current_user, project: project, role: 'owner')
      respond_with :message, text: t('commands.projects.create.success',
                                     name: project.name,
                                     slug: project.slug)
    else
      respond_with :message, text: t('commands.projects.create.error',
                                     reason: project.errors.full_messages.join(', '))
    end
  end

  def update_project_both(project, new_name, new_slug)
    # Валидация нового slug
    return show_error_message(t('commands.projects.rename.slug_invalid')) if invalid_slug?(new_slug)

    # Проверка уникальности нового slug (исключая текущий проект)
    if Project.where.not(id: project.id).exists?(slug: new_slug)
      return show_error_message(t('commands.projects.rename.slug_taken', slug: new_slug))
    end

    old_name = project.name
    old_slug = project.slug

    if project.update(name: new_name, slug: new_slug)
      text = t('commands.projects.rename.success_both',
               old_name: old_name,
               new_name: new_name,
               old_slug: old_slug,
               new_slug: new_slug)
      respond_with :message, text: text
      show_project_menu(new_slug)
    else
      show_error_message(t('commands.projects.rename.error'))
    end
  end

  def delete_client(slug)
    project = current_user.projects.find_by(slug: slug)
    return show_projects_list unless project && project.can_be_managed_by?(current_user)

    if project.update(client: nil)
      respond_with :message, text: t('commands.projects.client.delete_success')
      show_client_menu(slug)
    else
      show_error_message(t('commands.projects.client.delete_error'))
    end
  end

  def show_error_message(message)
    respond_with :message, text: message
  end

  def invalid_slug?(slug)
    slug.blank? || slug.length > 15 || slug.match?(/[^a-z0-9-]/) || slug.match?(/^-|-$/)
  end
end
