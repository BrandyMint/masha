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

  private

  def rename_project_directly(project_slug, new_name)
    project = find_project(project_slug)
    unless project
      respond_with :message, text: format(RenameConfig::MESSAGES[:project_not_found], project_slug)
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
      respond_with :message, text: RenameConfig::MESSAGES[:no_manageable_projects]
      return
    end

    respond_with :message,
                 text: RenameConfig::MESSAGES[:select_project],
                 reply_markup: {
                   inline_keyboard: manageable_projects.map do |p|
                     [{ text: "#{p.name} (#{p.slug})", callback_data: "rename_project:#{p.slug}" }]
                   end
                 }
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
      edit_message :text, text: RenameConfig::MESSAGES[:no_permission]
      return
    end

    self.telegram_session = TelegramSession.rename(project_id: project.id)
    save_context :rename_new_name_input
    edit_message :text, text: format(RenameConfig::MESSAGES[:enter_new_name], project.name)
  end

  def rename_new_name_input(new_name, *)
    if new_name.blank?
      respond_with :message, text: RenameConfig::MESSAGES[:validation_error]
      return
    end

    tg_session = telegram_session
    project_id = tg_session['project_id']
    project = current_user.available_projects.find(project_id)

    unless project
      clear_telegram_session
      respond_with :message, text: 'Проект не найден. Операция отменена.'
      return
    end

    # Validate new name using service
    service = ProjectRenameService.new
    result = service.call(current_user, project, new_name)

    unless result[:success]
      respond_with :message, text: result[:message]
      return
    end

    # Store new name in session and show confirmation
    tg_session[:new_name] = new_name
    self.telegram_session = tg_session

    save_context :rename_confirm_callback_query

    text = format(
      RenameConfig::MESSAGES[:confirm_rename],
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
      edit_message :text, text: RenameConfig::MESSAGES[:rename_cancelled]
      return
    end

    tg_session = telegram_session
    project_id = tg_session['project_id']
    new_name = tg_session['new_name']

    project = current_user.available_projects.find(project_id)
    unless project
      clear_telegram_session
      edit_message :text, text: 'Проект не найден. Операция отменена.'
      return
    end

    service = ProjectRenameService.new
    result = service.call(current_user, project, new_name)

    # Clean up session
    clear_telegram_session

    edit_message :text, text: result[:message]
  end
end