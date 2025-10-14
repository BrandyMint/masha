# frozen_string_literal: true

module Telegram
  module Concerns
    module PaginationConcern
      extend ActiveSupport::Concern

      def calculate_pagination(count, page, per_page)
        total_pages = (count.to_f / per_page).ceil
        offset = (page - 1) * per_page

        {
          current_page: page,
          total_pages: total_pages,
          per_page: per_page,
          offset: offset,
          has_next: page < total_pages,
          has_prev: page > 1
        }
      end

      def valid_page?(page, total_pages)
        page.is_a?(Integer) && page >= 1 && page <= total_pages
      end

      def build_pagination_keyboard(current_page, total_pages, callback_prefix:)
        return nil if total_pages <= 1

        keyboard_buttons = []
        nav_row = []

        nav_row << { text: "⬅️ Назад", callback_data: "#{callback_prefix}:#{current_page - 1}" } if current_page > 1
        nav_row << { text: "#{current_page}/#{total_pages}", callback_data: "noop" }
        nav_row << { text: "Вперед ➡️", callback_data: "#{callback_prefix}:#{current_page + 1}" } if current_page < total_pages

        keyboard_buttons << nav_row if nav_row.any?

        {
          inline_keyboard: keyboard_buttons
        }
      end

      def extract_page_from_callback(callback_data, prefix)
        match_data = callback_data.match(/^#{prefix}:(\d+)$/)
        return nil unless match_data

        match_data[1].to_i
      end
    end
  end
end