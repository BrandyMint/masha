# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Edit
    class TableFormatter
      include FormatHelpers

      def format_time_shifts_table(time_shifts, pagination)
        table = build_table(time_shifts)
        header = build_header(pagination)

        code("#{header}\n\n#{table}")
      end

      private

      def build_table(time_shifts)
        table = Terminal::Table.new do |t|
          t << %w[ID Дата Проект Часы Описание]
          t << :separator

          time_shifts.each do |shift|
            t << format_row(shift)
          end
        end

        table.align_column(0, :right)
        table.align_column(3, :right)

        table
      end

      def format_row(time_shift)
        description = format_description(time_shift.description)

        [
          time_shift.id,
          time_shift.date.to_s,
          time_shift.project.slug,
          time_shift.hours,
          description
        ]
      end

      def format_description(description)
        return '' if description.blank?

        description = description.to_s
        description = "#{description[0..30]}..." if description.length > 30
        description
      end

      def build_header(pagination)
        if pagination[:total_pages] > 1
          "Ваши записи времени (страница #{pagination[:current_page]} из #{pagination[:total_pages]}):"
        else
          'Ваши записи времени:'
        end
      end
    end
  end
end
