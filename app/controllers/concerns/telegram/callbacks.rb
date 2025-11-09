# frozen_string_literal: true

module Telegram
  module Callbacks
    extend ActiveSupport::Concern

    def callback_query(data)
      # Handle rename callbacks
      if data.start_with?('rename_project:')
        project_slug = data.sub('rename_project:', '')
        rename_project_callback_query(project_slug)
        return
      end

      if data.start_with?('rename_confirm:')
        action = data.sub('rename_confirm:', '')
        rename_confirm_callback_query(action)
        return
      end

      # Handle pagination callbacks
      if data.match?(/^edit_page:\d+$/)
        handle_edit_pagination_callback(data)
        return
      end

      edit_message :text, text: "Вы выбрали #{data}"
    end

    def select_project_callback_query(project_slug)
      save_context :add_time
      project = find_project project_slug
      self.telegram_session = TelegramSession.add_time(project_id: project.id)
      edit_message :text,
                   text: "Вы выбрали проект #{project.slug}, теперь укажите время и через пробел комментарий (12 делал то-то)"
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
      save_context :adduser_username_input
      edit_message :text, text: "Проект: #{project.name}\nТеперь введите никнейм пользователя (например: @username или username):"
    end

    def adduser_username_input(username, *)
      username = username.delete_prefix('@') if username.start_with?('@')
      tg_session = telegram_session
      tg_session[:username] = username
      self.telegram_session = tg_session

      save_context :adduser_role_callback_query
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

    def adduser_role_callback_query(role)
      data = telegram_session_data
      project_slug = data['project_slug']
      username = data['username']

      # Clean up session
      clear_telegram_session

      edit_message :text, text: "Добавляем пользователя @#{username} в проект #{project_slug} с ролью #{role}..."

      add_user_to_project(project_slug, username, role)
    end

    def add_time(hours, *description)
      data = telegram_session_data
      project = current_user.available_projects.find(data['project_id']) || raise('Не указан проект')
      description = description.join(' ')
      project.time_shifts.create!(
        date: Time.zone.today,
        hours: hours.to_s.tr(',', '.').to_f,
        description: description,
        user: current_user
      )

      clear_telegram_session
      respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
    end

    def new_project_slug_input(slug, *)
      if slug.blank?
        respond_with :message, text: 'Slug не может быть пустым. Укажите slug для нового проекта:'
        return
      end

      project = current_user.projects.create!(name: slug, slug: slug)
      respond_with :message, text: "Создан проект `#{project.slug}`"
    rescue ActiveRecord::RecordInvalid => e
      respond_with :message, text: "Ошибка создания проекта: #{e.message}"
    end

    def handle_edit_pagination_callback(callback_data)
      service = Telegram::Edit::PaginationService.new(self, current_user)
      page = service.handle_callback(callback_data)
      return unless page

      command = Commands::EditCommand.new(self)
      command.show_time_shifts_list(page)
    end

    # Rename project callbacks
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

    # Edit time shift callbacks
    def edit_select_time_shift_input(time_shift_id, *)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_selection(time_shift_id)
    end

    def edit_field_callback_query(field)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_field_selection(field)
    end

    def edit_project_callback_query(project_slug)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_project_selection(project_slug)
    end

    def edit_hours_input(hours_str, *)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_hours_input(hours_str)
    end

    def edit_description_input(description, *)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_description_input(description)
    end

    def edit_confirm_callback_query(action)
      service = Telegram::Edit::TimeShiftService.new(self, current_user)
      service.handle_confirmation(action)
    end
  end
end
