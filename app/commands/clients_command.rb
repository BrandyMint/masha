# frozen_string_literal: true

class ClientsCommand < BaseCommand
  # Декларируем контекстные методы, которые эта команда предоставляет контроллеру
  provides_context_methods ADD_CLIENT_NAME, ADD_CLIENT_KEY, EDIT_CLIENT_NAME

  def call(subcommand = nil, *args)
    return respond_with :message, text: 'Вы не аваторизованы для работы с клиентами' if current_user.blank?
    # Если нет аргументов, покажем список клиентов
    return show_clients_list if subcommand.blank?

    handle_client_command(subcommand, args)
  end

  # Public context handler methods - эти методы должны быть доступны для telegram-bot gem
  def add_client_name(message = nil, *)
    name = message&.strip
    if name.blank? || name.length > 255
      save_context ADD_CLIENT_NAME
      return respond_with :message, text: t('telegram.commands.clients.name_invalid')
    end

    session[:client_name] = name
    save_context ADD_CLIENT_KEY
    respond_with :message, text: t('telegram.commands.clients.add_prompt_key')
  end

  def add_client_key(message = nil, *)
    key = message&.strip&.downcase
    name = session[:client_name]

    # Валидация ключа
    if key.blank? || !key.match?(/\A[a-z0-9_-]+\z/) || key.length < 2 || key.length > 50
      save_context ADD_CLIENT_KEY
      return respond_with :message, text: t('telegram.commands.clients.key_invalid', key: key)
    end

    # Проверка уникальности ключа
    if current_user.clients.exists?(key: key)
      save_context ADD_CLIENT_KEY
      return respond_with :message, text: t('telegram.commands.clients.key_exists', key: key)
    end

    # Создание клиента
    client = current_user.clients.build(key: key, name: name)
    if client.save
      session.delete(:client_name)
      respond_with :message, text: t('telegram.commands.clients.add_success', name: client.name, key: client.key)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context ADD_CLIENT_KEY
    end
  end

  def edit_client_name(message = nil, *)
    name = message&.strip
    key = session[:edit_client_key]

    if name.blank? || name.length > 255
      save_context EDIT_CLIENT_NAME
      return respond_with :message, text: t('telegram.commands.clients.name_invalid')
    end

    client = find_client(key)
    return unless client

    if client.update(name: name)
      session.delete(:edit_client_key)
      respond_with :message, text: t('telegram.commands.clients.edit_success', key: client.key, name: client.name)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context EDIT_CLIENT_NAME
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
    when 'help'
      show_client_help
    else
      respond_with :message, text: t('telegram.commands.clients.usage_error')
    end
  end

  def show_clients_list
    clients = current_user.clients.includes(:projects)

    return respond_with :message, text: t('telegram.commands.clients.list_empty') if clients.empty?

    text = multiline(t('telegram.commands.clients.list_title'), nil)
    clients.each do |client|
      text += t('telegram.commands.clients.list_item',
                key: client.key,
                name: client.name,
                count: client.projects_count) + "\n"
    end

    respond_with :message, text: text
  end

  def handle_add_client
    save_context ADD_CLIENT_NAME
    respond_with :message, text: t('telegram.commands.clients.add_prompt_name')
  end

  def handle_show_client(key)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless current_user.can_read?(client)

    respond_with :message, text: format_client_info(client)
  end

  def handle_edit_client(key)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.edit_access_denied') unless current_user.can_update?(client)

    session[:edit_client_key] = key
    save_context EDIT_CLIENT_NAME
    respond_with :message, text: t('telegram.commands.clients.edit_prompt_name')
  end

  def handle_delete_client(key, confirm = nil)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.delete_access_denied') unless current_user.can_delete?(client)

    # Проверка на связанные проекты
    return respond_with :message, text: t('telegram.commands.clients.delete_has_projects', key: key) if client.projects.exists?

    # Запрос подтверждения
    unless confirm == 'confirm'
      return respond_with :message, text: t('telegram.commands.clients.delete_confirm', name: client.name, key: key)
    end

    # Удаление клиента
    if client.destroy
      respond_with :message, text: t('telegram.commands.clients.delete_success', name: client.name, key: key)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
    end
  end

  def handle_list_projects(key)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.projects_access_denied') unless current_user.can_read?(client)

    projects = client.projects.includes(:memberships)
    return respond_with :message, text: t('telegram.commands.clients.projects_empty') if projects.empty?

    text = multiline(t('telegram.commands.clients.projects_title', name: client.name, key: key), nil)
    projects.each do |project|
      text += "• #{project.name} (#{project.slug})\n"
    end

    respond_with :message, text: text
  end

  def show_client_help
    help_text = multiline(
      t('telegram.commands.clients.help_title'),
      '',
      t('telegram.commands.clients.help_commands_title'),
      t('telegram.commands.clients.help_list'),
      t('telegram.commands.clients.help_add'),
      t('telegram.commands.clients.help_show'),
      t('telegram.commands.clients.help_edit'),
      t('telegram.commands.clients.help_delete'),
      t('telegram.commands.clients.help_projects'),
      t('telegram.commands.clients.help_help'),
      '',
      t('telegram.commands.clients.help_examples_title'),
      t('telegram.commands.clients.help_example_1'),
      t('telegram.commands.clients.help_example_2'),
      t('telegram.commands.clients.help_example_3')
    )
    respond_with :message, text: help_text
  end

  def find_client(key)
    client = current_user.clients.find_by(key: key)
    respond_with :message, text: t('telegram.commands.clients.show_not_found', key: key) unless client
    client
  end

  def format_client_info(client)
    projects = client.projects.includes(:memberships)
    text = multiline(
      t('telegram.commands.clients.show_title'),
      t('telegram.commands.clients.show_key', key: client.key),
      t('telegram.commands.clients.show_name', name: client.name),
      t('telegram.commands.clients.show_projects_count', count: projects.count),
      ''
    )

    if projects.any?
      text += t('telegram.commands.clients.show_projects_list') + "\n"
      projects.each do |project|
        text += "• #{project.name} (#{project.slug})\n"
      end
    else
      text += t('telegram.commands.clients.show_empty_projects')
    end

    text
  end
end
