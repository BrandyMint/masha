# frozen_string_literal: true

module Telegram
  module Edit
    class PaginationService
      include Telegram::Concerns::PaginationConcern

      attr_reader :controller, :user, :per_page

      def initialize(controller, user)
        @controller = controller
        @user = user
        @per_page = ApplicationConfig.telegram_edit_per_page
      end

      def get_paginated_time_shifts(page = 1)
        total_count = user.time_shifts.count
        pagination = calculate_pagination(total_count, page, per_page)

        time_shifts = user.time_shifts
                           .includes(:project)
                           .order(date: :desc, created_at: :desc)
                           .limit(pagination[:per_page])
                           .offset(pagination[:offset])

        {
          time_shifts: time_shifts,
          pagination: pagination,
          total_count: total_count
        }
      end

      def save_pagination_context(pagination)
        controller.session[:edit_pagination] = {
          current_page: pagination[:current_page],
          total_pages: pagination[:total_pages]
        }
      end

      def validate_page(page)
        pagination_context = controller.session[:edit_pagination]
        return false unless pagination_context

        valid_page?(page, pagination_context[:total_pages])
      end

      def build_keyboard(pagination)
        build_pagination_keyboard(
          pagination[:current_page],
          pagination[:total_pages],
          callback_prefix: 'edit_page'
        )
      end

      def handle_callback(callback_data)
        page = extract_page_from_callback(callback_data, 'edit_page')
        return nil unless page && validate_page(page)

        page
      end
    end
  end
end