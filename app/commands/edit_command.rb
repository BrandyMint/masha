# frozen_string_literal: true

module Commands
    class EditCommand < BaseCommand
      def call(*)
        service = Telegram::Edit::TimeShiftService.new(controller, current_user)
        service.show_time_shifts_list(1)
      end

      def show_time_shifts_list(page = 1)
        service = Telegram::Edit::TimeShiftService.new(controller, current_user)
        service.show_time_shifts_list(page)
  end
end
end
