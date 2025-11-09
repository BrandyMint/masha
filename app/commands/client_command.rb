# frozen_string_literal: true

class ClientCommand < BaseCommand
  def call(subcommand = nil, *args)
    # Если нет аргументов, покажем список клиентов
    return show_clients_list if subcommand.blank?

    handle_client_command(subcommand, args)
  end

  # Public context handler methods - эти методы должны быть доступны для telegram-bot gem
  def add_client_name(message = nil, *)
    name = message&.strip
    if name.blank? || name.length > 255
      respond_with :message, text: t('telegram.commands.client.name_invalid')
      save_context :add_client_name
      return
    end

    session[:client_name] = name
    save_context :add_client_key
    respond_with :message, text: t('telegram.commands.client.add_prompt_key')
  end

  def add_client_key(message = nil, *)
    key = message&.strip&.downcase
    name = session[:client_name]

    # Валидация ключа
    if key.blank? || !key.match?(/\A[a-z0-9_-]+\z/) || key.length < 2 || key.length > 50
      respond_with :message, text: t('telegram.commands.client.key_invalid', key: key)
      save_context :add_client_key
      return
    end

    # Проверка уникальности ключа
    if current_user.clients.exists?(key: key)
      respond_with :message, text: t('telegram.commands.client.key_exists', key: key)
      save_context :add_client_key
      return
    end

    # Создание клиента
    client = current_user.clients.build(key: key, name: name)
    if client.save
      session.delete(:client_name)
      respond_with :message, text: t('telegram.commands.client.add_success', name: client.name, key: client.key)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context :add_client_key
    end
  end

  def edit_client_name(message = nil, *)
    name = message&.strip
    key = session[:edit_client_key]

    if name.blank? || name.length > 255
      respond_with :message, text: t('telegram.commands.client.name_invalid')
      save_context :edit_client_name
      return
    end

    client = find_client(key)
    return unless client

    if client.update(name: name)
      session.delete(:edit_client_key)
      respond_with :message, text: t('telegram.commands.client.edit_success', key: client.key, name: client.name)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context :edit_client_name
    end
  end

  private

  def handle_client_command(subcommand, args)
    command = subcommand.downcase

    case command
    when 'add'
      handle_add_client
    when 'show'
      handle_show_client(args[0])
    when 'edit'
      handle_edit_client(args[0])
    when 'delete'
      handle_delete_client(args[0], args[1])
    when 'projects'
      handle_list_projects(args[0])
    when 'attach'
      handle_attach_project(args[0], args[1])
    when 'detach'
      handle_detach_project(args[0], args[1])
    when 'help'
      show_client_help
    else
      respond_with :message, text: t('telegram.commands.client.usage_error')
    end
  end

  def show_clients_list
    clients = current_user.clients.includes(:projects)

    if clients.empty?
      respond_with :message, text: t('telegram.commands.client.list_empty')
      return
    end

    text = multiline(t('telegram.commands.client.list_title'), nil)
    clients.each do |client|
      text += t('telegram.commands.client.list_item',
                key: client.key,
                name: client.name,
                count: client.projects_count) + "\n"
    end

    respond_with :message, text: text
  end

  def handle_add_client
    save_context :add_client_name
    respond_with :message, text: t('telegram.commands.client.add_prompt_name')
  end

  def handle_show_client(key)
    unless key
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_read?(client)
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    respond_with :message, text: format_client_info(client)
  end

  def handle_edit_client(key)
    unless key
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_update?(client)
      respond_with :message, text: t('telegram.commands.client.edit_access_denied')
      return
    end

    session[:edit_client_key] = key
    save_context :edit_client_name
    respond_with :message, text: t('telegram.commands.client.edit_prompt_name')
  end

  def handle_delete_client(key, confirm = nil)
    unless key
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_delete?(client)
      respond_with :message, text: t('telegram.commands.client.delete_access_denied')
      return
    end

    # Проверка на связанные проекты
    if client.projects.exists?
      respond_with :message, text: t('telegram.commands.client.delete_has_projects', key: key)
      return
    end

    # Запрос подтверждения
    unless confirm == 'confirm'
      respond_with :message, text: t('telegram.commands.client.delete_confirm', name: client.name, key: key)
      return
    end

    # Удаление клиента
    if client.destroy
      respond_with :message, text: t('telegram.commands.client.delete_success', name: client.name, key: key)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
    end
  end

  def handle_list_projects(key)
    unless key
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_read?(client)
      respond_with :message, text: t('telegram.commands.client.projects_access_denied')
      return
    end

    projects = client.projects.includes(:memberships)
    if projects.empty?
      respond_with :message, text: t('telegram.commands.client.projects_empty')
      return
    end

    text = multiline(t('telegram.commands.client.projects_title', name: client.name, key: key), nil)
    projects.each do |project|
      text += "• #{project.name} (#{project.slug})\n"
    end

    respond_with :message, text: text
  end

  def handle_attach_project(key, project_name)
    unless key && project_name
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_update?(client)
      respond_with :message, text: t('telegram.commands.client.attach_access_denied')
      return
    end

    project = find_project(project_name)
    unless project
      respond_with :message, text: t('telegram.commands.client.attach_project_not_found', project_name: project_name)
      return
    end

    unless project.users.include?(current_user)
      respond_with :message, text: t('telegram.commands.client.attach_project_not_found', project_name: project_name)
      return
    end

    if project.update(client: client)
      respond_with :message,
                   text: t('telegram.commands.client.attach_success', project_name: project.name, name: client.name, key: client.key)
    else
      respond_with :message, text: project.errors.full_messages.join(', ')
    end
  end

  def handle_detach_project(key, project_name)
    unless key && project_name
      respond_with :message, text: t('telegram.commands.client.usage_error')
      return
    end

    client = find_client(key)
    return unless client

    unless current_user.can_update?(client)
      respond_with :message, text: t('telegram.commands.client.detach_access_denied')
      return
    end

    project = find_project(project_name)
    unless project
      respond_with :message, text: t('telegram.commands.client.detach_project_not_found', project_name: project_name)
      return
    end

    unless project.client == client
      respond_with :message, text: t('telegram.commands.client.detach_project_not_found', project_name: project_name)
      return
    end

    if project.update(client: nil)
      respond_with :message,
                   text: t('telegram.commands.client.detach_success', project_name: project.name, name: client.name, key: client.key)
    else
      respond_with :message, text: project.errors.full_messages.join(', ')
    end
  end

  def show_client_help
    help_text = multiline(
      t('telegram.commands.client.help_title'),
      '',
      t('telegram.commands.client.help_commands_title'),
      t('telegram.commands.client.help_list'),
      t('telegram.commands.client.help_add'),
      t('telegram.commands.client.help_show'),
      t('telegram.commands.client.help_edit'),
      t('telegram.commands.client.help_delete'),
      t('telegram.commands.client.help_projects'),
      t('telegram.commands.client.help_attach'),
      t('telegram.commands.client.help_detach'),
      t('telegram.commands.client.help_help'),
      '',
      t('telegram.commands.client.help_examples_title'),
      t('telegram.commands.client.help_example_1'),
      t('telegram.commands.client.help_example_2'),
      t('telegram.commands.client.help_example_3')
    )
    respond_with :message, text: help_text
  end

  def find_client(key)
    client = current_user.clients.find_by(key: key)
    respond_with :message, text: t('telegram.commands.client.show_not_found', key: key) unless client
    client
  end

  def format_client_info(client)
    projects = client.projects.includes(:memberships)
    text = multiline(
      t('telegram.commands.client.show_title'),
      t('telegram.commands.client.show_key', key: client.key),
      t('telegram.commands.client.show_name', name: client.name),
      t('telegram.commands.client.show_projects_count', count: projects.count),
      ''
    )

    if projects.any?
      text += t('telegram.commands.client.show_projects_list') + "\n"
      projects.each do |project|
        text += "• #{project.name} (#{project.slug})\n"
      end
    else
      text += t('telegram.commands.client.show_empty_projects')
    end

    text
  end
end
