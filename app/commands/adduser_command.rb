# frozen_string_literal: true

class AdduserCommand < BaseCommand
  provides_context_methods :adduser_project, :adduser_username_input

  def call(project_slug = nil, username = nil, role = 'member', *)
    return show_manageable_projects if project_slug.blank?

    return respond_with :message, text: 'Укажите никнейм пользователя (например: @username или username)' if username.blank?

    TelegramProjectManager.new(current_user, controller: controller)
                          .add_user_to_project(project_slug, username, role)
  end

  def adduser_project(project_slug)
    call(project_slug)
  end

  # Публичные методы для context methods
  def adduser_username_input(username, *)
    username = username.delete_prefix('@') if username.start_with?('@')
    tg_session = telegram_session
    tg_session[:username] = username
    self.telegram_session = tg_session

    # Контекст будет установлен через callback_query автоматически
    respond_with :message,
                 text: "Пользователь: @#{username}\nВыберите роль для пользователя:",
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: 'Владелец (owner)', callback_data: 'adduser_role:owner' }],
                     [{ text: 'Наблюдатель (viewer)', callback_data: 'adduser_role:viewer' }],
                     [{ text: 'Участник (member)', callback_data: 'adduser_role:member' }]
                   ]
                 }
  end

  def adduser_project_callback_query(project_slug)
    project = find_project(project_slug)
    unless project
      edit_message :text, text: 'Проект не найден'
      return
    end

    # Check permissions - only owners can add users
    membership = current_user.membership_of(project)
    unless membership&.owner?
      edit_message :text, text: 'У вас нет прав для добавления пользователей в этот проект, только владелец (owner) может это сделать.'
      return
    end

    self.telegram_session = TelegramSession.add_user(project_slug: project_slug)
    save_context ADDUSER_USERNAME_INPUT
    edit_message :text, text: "Проект: #{project.name}\nТеперь введите никнейм пользователя (например: @username или username):"
  end

  def adduser_role_callback_query(role)
    data = telegram_session_data
    project_slug = data['project_slug']
    username = data['username']

    # Clean up session
    clear_telegram_session

    edit_message :text, text: "Добавляем пользователя @#{username} в проект #{project_slug} с ролью #{role}..."

    add_user_to_project(project_slug, username, role)
  end

  private

  def show_manageable_projects
    if current_user.nil?
      return respond_with :message, text: 'У Вас пока нет проектов'
    end
    manageable_projects = current_user.available_projects.alive.joins(:memberships)
                                      .where(memberships: { user: current_user, role_cd: 0 })

    return respond_with :message, text: 'У Вас пока нет проектов, в которые можно добавить пользователей' if manageable_projects.empty?

    # Контекст будет установлен через callback_query автоматически
    respond_with :message,
                 text: 'Выберите проект, в который хотите добавить пользователя:',
                 reply_markup: {
                   inline_keyboard: manageable_projects.map { |p| [{ text: p.name, callback_data: "adduser_project:#{p.slug}" }] }
                 }
  end
end
