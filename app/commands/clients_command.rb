# frozen_string_literal: true

class ClientsCommand < BaseCommand
  # Декларируем контекстные методы, которые эта команда предоставляет контроллеру
  provides_context_methods :clients_name, :clients_key, :clients_rename, :clients_delete_confirm

  def call(subcommand = nil, *args)
    return respond_with :message, text: 'Вы не авторизованы' if current_user.blank?

    # Если нет аргументов - показать интерактивный UI
    return show_clients_list if subcommand.blank?

    # Legacy формат для обратной совместимости
    handle_client_command(subcommand, args)
  end


  def clients_name(message = nil, *)
    return respond_with(:message, text: t('telegram.commands.clients.name_invalid')) unless message

    name = message.strip
    if name.blank? || name.length > 255
      save_context :clients_name
      return respond_with :message, text: t('telegram.commands.clients.name_invalid')
    end

    session[:new_client_name] = name
    save_context :clients_key
    respond_with :message, text: t('telegram.commands.clients.add_prompt_key')
  end

  def clients_key(message = nil, *)
    return respond_with(:message, text: t('telegram.commands.clients.key_invalid')) unless message

    key = message.strip.downcase
    name = session[:new_client_name]

    # Валидация ключа
    if key.blank? || key.length > 50 || !key.match?(/\A[a-z0-9_-]+\z/)
      save_context :clients_key
      return respond_with :message, text: t('telegram.commands.clients.key_invalid')
    end

    # Проверка уникальности ключа
    if current_user.clients.exists?(key: key)
      save_context :clients_key
      return respond_with :message, text: t('telegram.commands.clients.key_taken')
    end

    # Создание клиента
    client = current_user.clients.build(key: key, name: name)
    if client.save
      session.delete(:new_client_name)
      respond_with :message, text: t('telegram.commands.clients.add_success', name: client.name, key: client.key)
      show_clients_list
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context :clients_key
    end
  end

  def clients_rename(message = nil, *)
    return respond_with(:message, text: t('telegram.commands.clients.name_invalid')) unless message

    name = message.strip
    key = session[:edit_client_key]

    if name.blank? || name.length > 255
      save_context :clients_rename
      return respond_with :message, text: t('telegram.commands.clients.name_invalid')
    end

    client = find_client(key)
    return unless client

    if client.update(name: name)
      session.delete(:edit_client_key)
      respond_with :message, text: t('telegram.commands.clients.edit_success', key: client.key, name: client.name)
      show_client_menu(client)
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context :clients_rename
    end
  end

  def clients_delete_confirm(message = nil, *)
    return respond_with(:message, text: t('telegram.commands.clients.delete_confirm_error')) unless message

    key = session[:delete_client_key]
    client = find_client(key)
    return unless client

    confirmation = message.strip.downcase
    expected_confirmation = t('telegram.commands.clients.delete_confirm_word', default: 'удалить')

    if confirmation != expected_confirmation.downcase
      save_context :clients_delete_confirm
      return respond_with :message, text: t('telegram.commands.clients.delete_confirm_mismatch', expected: expected_confirmation)
    end

    name = client.name
    key_name = client.key

    if client.destroy
      session.delete(:delete_client_key)
      respond_with :message, text: t('telegram.commands.clients.delete_success', name: name, key: key_name)
      show_clients_list
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
      save_context :clients_delete_confirm
    end
  end

  # Callback methods

  # Callback methods

  def clients_create_callback_query(_data = nil)
    session[:new_client_name] = nil
    save_context :clients_name
    respond_with :message, text: t('telegram.commands.clients.add_prompt_name')
    safe_answer_callback_query
  end

  def clients_select_callback_query(data)
    raise RuntimeError, 'clients_select_callback_query called without data' unless data.present?

    client = find_client(data)

    return respond_with :message, text: 'Такой клиент не найден или у вас нет доступа' unless client
    return respond_with :message, text: t('telegram.commands.clients.show_access_denied') unless current_user.can_read?(client)

    show_client_menu(client)
    safe_answer_callback_query
  end

  def clients_list_callback_query(_data = nil)
    show_clients_list
    safe_answer_callback_query
  end

  def clients_rename_callback_query(data)
    raise RuntimeError, 'clients_select_callback_query called without data' unless data.present?
    client = find_client(data)
    return respond_with :message, text: 'Такой клиент не найден или у вас нет доступа' unless client

    return respond_with :message, text: t('telegram.commands.clients.edit_access_denied') unless current_user.can_update?(client)

    session[:edit_client_key] = client.key
    save_context :clients_rename
    respond_with :message, text: t('telegram.commands.clients.edit_prompt_name')
    safe_answer_callback_query
  end

  def clients_projects_callback_query(data)
    client = find_client(data)
    return respond_with :message, text: 'Такой клиент не найден или у вас нет доступа' unless client
    return respond_with :message, text: t('telegram.commands.clients.projects_access_denied') unless current_user.can_read?(client)

    show_client_projects(client)
    safe_answer_callback_query
  end

  def clients_delete_callback_query(data)
    raise RuntimeError, 'clients_select_callback_query called without data' unless data.present?
    client = find_client(data)
    return respond_with :message, text: 'Такой клиент не найден или у вас нет доступа' unless client
    return respond_with :message, text: t('telegram.commands.clients.delete_access_denied') unless current_user.can_delete?(client)

    if client.projects.exists?
      return respond_with :message, text: t('telegram.commands.clients.delete_has_projects', key: client.key)
    end

    text = t('telegram.commands.clients.delete_confirm', name: client.name, key: client.key)
    buttons = [
      [{ text: t('telegram.commands.clients.delete_confirm_button'), callback_data: "clients_delete_confirm:#{client.key}" }],
      [{ text: t('telegram.commands.clients.back_button'), callback_data: "clients_select:#{client.key}" }]
    ]

    respond_with :message, text: text, reply_markup: { inline_keyboard: buttons }
    safe_answer_callback_query
  end

  def clients_delete_confirm_callback_query(data)
    client = find_client(data)
    return respond_with :message, text: 'Такой клиент не найден или у вас нет доступа' unless client
    return respond_with :message, text: t('telegram.commands.clients.delete_access_denied') unless current_user.can_delete?(client)

    if client.projects.exists?
      return respond_with :message, text: t('telegram.commands.clients.delete_has_projects', key: client.key)
    end

    name = client.name
    key = client.key

    if client.destroy
      respond_with :message, text: t('telegram.commands.clients.delete_success', name: name, key: key)
      show_clients_list
    else
      respond_with :message, text: client.errors.full_messages.join(', ')
    end
    safe_answer_callback_query
  end

  private

  def handle_client_command(subcommand, args)
    command = subcommand.downcase

    case command
    when 'list'
      show_clients_list
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
    clients = current_user.clients.alphabetically.limit(30)

    buttons = []
    # Добавить кнопку "Добавить клиента"
    buttons << [{ text: t('telegram.commands.clients.add_button'), callback_data: 'clients_create:' }]

    # Добавить кнопки клиентов (по 3 в ряд)
    client_buttons = clients.map { |c| { text: c.name.truncate(15), callback_data: "clients_select:#{c.key}" } }
    client_buttons.each_slice(3) { |row| buttons << row }

    respond_with :message, text: t('telegram.commands.clients.list_title'), reply_markup: { inline_keyboard: buttons }
  end

  def handle_add_client
    session[:new_client_name] = nil
    save_context :clients_name
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
    save_context :clients_rename
    respond_with :message, text: t('telegram.commands.clients.edit_prompt_name')
  end

  def handle_delete_client(key, _confirm = nil)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.delete_access_denied') unless current_user.can_delete?(client)

    # Проверка на связанные проекты
    if client.projects.exists?
      return respond_with :message, text: t('telegram.commands.clients.delete_projects_exists')
    end

    # Запускаем многошаговый диалог для подтверждения
    session[:delete_client_key] = key
    save_context :clients_delete_confirm

    respond_with :message, text: t('telegram.commands.clients.delete_confirm_prompt', name: client.name)
  end

  def handle_list_projects(key)
    return respond_with :message, text: t('telegram.commands.clients.usage_error') unless key

    client = find_client(key)
    return unless client

    return respond_with :message, text: t('telegram.commands.clients.projects_access_denied') unless current_user.can_read?(client)

    show_client_projects(client)
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
      text += t('telegram.commands.clients.show_projects_list') + "\\n"
      projects.each do |project|
        text += "• #{project.name} (#{project.slug})\\n"
      end
    else
      text += t('telegram.commands.clients.show_empty_projects')
    end

    text
  end


  def show_client_menu(client)
    can_manage = current_user.can_update?(client) && current_user.can_delete?(client)
    projects_count = client.projects.count

    menu_text = format_client_info(client)

    buttons = []

    if can_manage
      buttons << [{ text: t('telegram.commands.clients.edit_button'), callback_data: "clients_rename:#{client.key}" }]
    end

    buttons << [{ text: t('telegram.commands.clients.projects_button', count: projects_count), callback_data: "clients_projects:#{client.key}" }]

    if can_manage && projects_count == 0
      buttons << [{ text: t('telegram.commands.clients.delete_button'), callback_data: "clients_delete:#{client.key}" }]
    end

    buttons << [{ text: t('telegram.commands.clients.back_button'), callback_data: 'clients_list:' }]

    respond_with :message, text: menu_text, reply_markup: { inline_keyboard: buttons }
  end

  def show_client_projects(client)
    projects = client.projects.includes(:memberships)

    if projects.empty?
      text = t('telegram.commands.clients.projects_empty', name: client.name, key: client.key)
    else
      text = t('telegram.commands.clients.projects_title', name: client.name, key: client.key) + "\\n"
      projects.each do |project|
        text += "• #{project.name} (#{project.slug})\\n"
      end
    end

    buttons = [[{ text: t('telegram.commands.clients.back_button'), callback_data: "clients_select:#{client.key}" }]]

    respond_with :message, text: text, reply_markup: { inline_keyboard: buttons }
  end
end
