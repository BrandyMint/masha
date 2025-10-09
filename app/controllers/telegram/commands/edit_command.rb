# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Commands
    class EditCommand < BaseCommand
      def call(*)
        show_time_shifts_list(1)
      end

      private

      def show_time_shifts_list(page = 1)
        per_page = ApplicationConfig.telegram_edit_per_page
        offset = (page - 1) * per_page

        total_count = current_user.time_shifts.count
        total_pages = (total_count.to_f / per_page).ceil

        time_shifts = current_user.time_shifts
                                  .includes(:project)
                                  .order(date: :desc, created_at: :desc)
                                  .limit(per_page)
                                  .offset(offset)

        if time_shifts.empty?
          respond_with :message, text: 'У вас нет записей времени для редактирования'
          return
        end

        text = build_time_shifts_table(time_shifts, page, total_pages)
        save_pagination_context(page, total_pages)
        save_context :edit_select_time_shift_input

        reply_markup = build_pagination_keyboard(page, total_pages)

        respond_with :message,
                     text: multiline(
                       text,
                       nil,
                       'Введите ID записи, которую хотите редактировать:'
                     ),
                     reply_markup:,
                     parse_mode: :Markdown
      end

      def build_time_shifts_table(time_shifts, page, total_pages)
        table = Terminal::Table.new do |t|
          t << %w[ID Дата Проект Часы Описание]
          t << :separator

          time_shifts.each do |shift|
            description = shift.description.to_s
            description = "#{description[0..30]}..." if description.length > 30
            t << [shift.id, shift.date.to_s, shift.project.slug, shift.hours, description]
          end
        end

        table.align_column(0, :right)
        table.align_column(3, :right)

        page_info = total_pages > 1 ? " (страница #{page} из #{total_pages})" : ""
        code("Ваши записи времени#{page_info}:\n\n#{table}")
      end

      def build_pagination_keyboard(current_page, total_pages)
        return nil if total_pages <= 1

        keyboard_buttons = []
        nav_row = []

        nav_row << { text: "⬅️ Назад", callback_data: "edit_page:#{current_page - 1}" } if current_page > 1
        nav_row << { text: "#{current_page}/#{total_pages}", callback_data: "noop" }
        nav_row << { text: "Вперед ➡️", callback_data: "edit_page:#{current_page + 1}" } if current_page < total_pages

        keyboard_buttons << nav_row if nav_row.any?

        {
          inline_keyboard: keyboard_buttons
        }
      end

      def save_pagination_context(page, total_pages)
        session[:edit_pagination] = {
          current_page: page,
          total_pages: total_pages
        }
      end
    end
  end
end
