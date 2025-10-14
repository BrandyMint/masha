# frozen_string_literal: true

module Telegram
  module Edit
    class TimeShiftService
      include Telegram::Concerns::PaginationConcern

      attr_reader :controller, :user

      def initialize(controller, user)
        @controller = controller
        @user = user
      end

      def show_time_shifts_list(page = 1)
        pagination_service = PaginationService.new(controller, user)
        result = pagination_service.get_paginated_time_shifts(page)

        if result[:time_shifts].empty?
          controller.respond_with :message, text: 'У вас нет записей времени для редактирования'
          return
        end

        table_formatter = TableFormatter.new(controller)
        text = table_formatter.format_time_shifts_table(result[:time_shifts], result[:pagination])

        pagination_service.save_pagination_context(result[:pagination])
        controller.save_context :edit_select_time_shift_input

        reply_markup = pagination_service.build_keyboard(result[:pagination])

        controller.respond_with :message,
                                text: controller.multiline(
                                  text,
                                  nil,
                                  'Введите ID записи, которую хотите редактировать:'
                                ),
                                reply_markup:,
                                parse_mode: :Markdown
      end

      def handle_selection(time_shift_id)
        time_shift = find_time_shift(time_shift_id)

        unless time_shift
          controller.respond_with :message, text: "Запись с ID #{time_shift_id} не найдена или недоступна"
          return
        end

        unless time_shift.updatable_by?(user)
          controller.respond_with :message, text: 'У вас нет прав для редактирования этой записи'
          return
        end

        # Save time shift to session using TelegramSession
        controller.telegram_session = TelegramSession.edit(
          time_shift_id: time_shift.id
        )

        controller.save_context :edit_field_callback_query
        show_field_selection(time_shift)
      end

      def handle_field_selection(field)
        if field == 'cancel'
          controller.clear_telegram_session
          controller.edit_message :text, text: 'Редактирование отменено'
          return
        end

        tg_session = controller.telegram_session
        tg_session[:field] = field
        controller.telegram_session = tg_session

        case field
        when 'project'
          show_project_selection
        when 'hours'
          show_hours_input
        when 'description'
          show_description_input
        end
      end

      def handle_project_selection(project_slug)
        project = find_project(project_slug)

        unless project
          controller.edit_message :text, text: 'Проект не найден'
          return
        end

        tg_session = controller.telegram_session
        tg_session[:new_values] = { project_id: project.id }
        controller.telegram_session = tg_session
        show_confirmation
      end

      def handle_hours_input(hours_str)
        hours = hours_str.to_s.tr(',', '.').to_f

        if hours < 0.1
          controller.respond_with :message, text: 'Количество часов должно быть не менее 0.1. Попробуйте еще раз:'
          return
        end

        tg_session = controller.telegram_session
        tg_session[:new_values] = { hours: hours }
        controller.telegram_session = tg_session
        show_confirmation
      end

      def handle_description_input(description)
        description = nil if description == '-'

        if description && description.length > 1000
          controller.respond_with :message, text: 'Описание не может быть длиннее 1000 символов. Попробуйте еще раз:'
          return
        end

        tg_session = controller.telegram_session
        tg_session[:new_values] = { description: description }
        controller.telegram_session = tg_session
        show_confirmation
      end

      def handle_confirmation(action)
        if action == 'cancel'
          controller.clear_telegram_session
          controller.edit_message :text, text: 'Изменения отменены'
          return
        end

        time_shift = controller.edit_time_shift
        unless time_shift
          controller.handle_missing_time_shift
          return
        end

        data = controller.telegram_session_data
        field = data['field']
        new_values = data['new_values']

        update_time_shift(time_shift, field, new_values)

        # Clean up session
        controller.clear_telegram_session
        controller.edit_message :text, text: "✅ Запись ##{time_shift.id} успешно обновлена!"
      rescue ActiveRecord::RecordInvalid => e
        controller.edit_message :text, text: "Ошибка при сохранении: #{e.message}"
      end

      private

      def find_time_shift(time_shift_id)
        user.time_shifts.find_by(id: time_shift_id)
      end

      def find_project(project_slug)
        user.available_projects.find_by(slug: project_slug)
      end

      def show_field_selection(time_shift)
        description = time_shift.description || '(нет)'
        text = "Запись ##{time_shift.id}:\n" \
               "Проект: #{time_shift.project.name}\n" \
               "Часы: #{time_shift.hours}\n" \
               "Описание: #{description}\n\n" \
               'Что хотите изменить?'

        controller.respond_with :message,
                                text: text,
                                reply_markup: {
                                  inline_keyboard: [
                                    [{ text: '📁 Проект', callback_data: 'edit_field:project' }],
                                    [{ text: '⏰ Часы', callback_data: 'edit_field:hours' }],
                                    [{ text: '📝 Описание', callback_data: 'edit_field:description' }],
                                    [{ text: '❌ Отмена', callback_data: 'edit_field:cancel' }]
                                  ]
                                }
      end

      def show_project_selection
        time_shift = controller.edit_time_shift
        return unless time_shift

        controller.save_context :edit_project_callback_query
        projects = user.available_projects.alive

        text = "Выберите новый проект (текущий: #{time_shift.project.name}):"

        inline_keyboard = projects.map do |p|
          project_name = p.id == time_shift.project_id ? "#{p.name} (текущий)" : p.name
          [{ text: project_name, callback_data: "edit_project:#{p.slug}" }]
        end

        controller.edit_message :text,
                                text: text,
                                reply_markup: { inline_keyboard: inline_keyboard }
      end

      def show_hours_input
        controller.save_context :edit_hours_input
        controller.edit_message :text, text: 'Введите новое количество часов (например, 8 или 7.5):'
      end

      def show_description_input
        controller.save_context :edit_description_input
        controller.edit_message :text, text: 'Введите новое описание (или отправьте "-" для пустого описания):'
      end

      def show_confirmation
        time_shift = controller.edit_time_shift
        return unless time_shift

        data = controller.telegram_session_data
        field = data['field']
        new_values = data['new_values']

        changes = controller.build_changes_text(time_shift, field, new_values)

        controller.save_context :edit_confirm_callback_query

        controller.respond_with :message,
                                text: "Подтвердите изменения:\n\n#{changes.join("\n")}\n\nСохранить?",
                                reply_markup: {
                                  inline_keyboard: [
                                    [{ text: '✅ Сохранить', callback_data: 'edit_confirm:save' }],
                                    [{ text: '❌ Отмена', callback_data: 'edit_confirm:cancel' }]
                                  ]
                                }
      end

      def update_time_shift(time_shift, field, new_values)
        case field
        when 'project'
          time_shift.update!(project_id: new_values['project_id'])
        when 'hours'
          time_shift.update!(hours: new_values['hours'])
        when 'description'
          time_shift.update!(description: new_values['description'])
        end
      end
    end
  end
end
