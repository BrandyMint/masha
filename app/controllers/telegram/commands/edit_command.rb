# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Commands
    class EditCommand < BaseCommand
      def call(*)
        show_time_shifts_list
      end

      private

      def show_time_shifts_list
        time_shifts = current_user.time_shifts
                                  .includes(:project)
                                  .order(date: :desc, created_at: :desc)
                                  .limit(50)

        if time_shifts.empty?
          respond_with :message, text: 'У вас нет записей времени для редактирования'
          return
        end

        text = build_time_shifts_table(time_shifts)
        save_context :edit_select_time_shift_input

        respond_with :message,
                     text: multiline(
                       text,
                       nil,
                       'Введите ID записи, которую хотите редактировать:'
                     ),
                     parse_mode: :Markdown
      end

      def build_time_shifts_table(time_shifts)
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

        code("Последние 50 записей:\n\n#{table}")
      end
    end
  end
end
