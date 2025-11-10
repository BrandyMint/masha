# frozen_string_literal: true

class RenameCommand < BaseCommand
  provides_context_methods :rename_project
  def call(project_slug = nil, *name_parts)
    if project_slug.present?
      # Прямое переименование: /rename project-slug "Новое название"
      new_name = name_parts.join(' ')
      rename_project_directly(project_slug, new_name)
    else
      # Показать список проектов для выбора
      show_projects_selection
    end
  end

  def rename_project(project_slug)
    call(project_slug)
  end

  def rename_project_callback_query(project_slug)
    project = find_project(project_slug)
    unless project
      edit_message :text, text: 'Проект не найден'
      return
    end

    # Check permissions - only owners can rename
    service = ProjectRenameService.new
    unless service.send(:can_rename?, current_user, project)
      edit_message :text, text: t('rename_command.no_permission')
      return
    end

    self.telegram_session = TelegramSession.rename(project_id: project.id)
    save_context RENAME_NEW_NAME_INPUT
    edit_message :text, text: format(t('rename_command.enter_new_name'), project.name)
  end

  private

  def rename_project_directly(project_slug, new_name)
    project = find_project(project_slug)
    unless project
      respond_with :message, text: format(t('rename_command.project_not_found'), project_slug)
      return
    end

    service = ProjectRenameService.new
    result = service.call(current_user, project, new_name)

    respond_with :message, text: result[:message]
  end

  def show_projects_selection
    service = ProjectRenameService.new
    manageable_projects = service.manageable_projects(current_user)

    if manageable_projects.empty?
      return respond_with :message, text: t('rename_command.no_manageable_projects')
    end

    respond_with :message,
                 text: t('rename_command.select_project'),
                 reply_markup: {
                   inline_keyboard: manageable_projects.map do |p|
                     [{ text: "#{p.name} (#{p.slug})", callback_data: "rename_project:#{p.slug}" }]
                   end
                 }
  end

  def rename_new_name_input(new_name, *)
    if new_name.blank?
      return respond_with :message, text: t('rename_command.validation_error')
    end

    tg_session = telegram_session
    project_id = tg_session['project_id']
    project = current_user.available_projects.find(project_id)

    unless project
      clear_telegram_session
      return respond_with :message, text: 'Проект не найден. Операция отменена.'
    end

    # Validate new name using service
    service = ProjectRenameService.new
    result = service.call(current_user, project, new_name)

    unless result[:success]
      return respond_with :message, text: result[:message]
    end

    # Store new name in session and show confirmation
    tg_session[:new_name] = new_name
    self.telegram_session = tg_session

    # Контекст будет установлен через callback_query автоматически

    text = format(
      t('rename_command.confirm_rename'),
      project.name, project.slug, new_name
    )

    respond_with :message,
                 text: text,
                 reply_markup: {
                   inline_keyboard: [
                     [{ text: '✅ Да, переименовать', callback_data: 'rename_confirm:save' }],
                     [{ text: '❌ Отмена', callback_data: 'rename_confirm:cancel' }]
                   ]
                 }
  end

  def rename_confirm_callback_query(action)
    if action == 'cancel'
      clear_telegram_session
      return edit_message :text, text: t('rename_command.rename_cancelled')
    end

    tg_session = telegram_session
    project_id = tg_session['project_id']
    new_name = tg_session['new_name']

    project = current_user.available_projects.find(project_id)
    unless project
      clear_telegram_session
      return edit_message :text, text: 'Проект не найден. Операция отменена.'
    end

    service = ProjectRenameService.new
    result = service.call(current_user, project, new_name)

    # Clean up session
    clear_telegram_session

    edit_message :text, text: result[:message]
  end
end
