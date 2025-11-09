# frozen_string_literal: true

class EditCommand < BaseCommand
  provides_context_methods EDIT_SELECT_TIME_SHIFT_INPUT, EDIT_HOURS_INPUT, EDIT_DESCRIPTION_INPUT
  def call(*)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.show_time_shifts_list(1)
  end

  def show_time_shifts_list(page = 1)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.show_time_shifts_list(page)
  end

  def edit_select_time_shift_input(time_shift_id, *)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_selection(time_shift_id)
  end

  def edit_hours_input(hours_str, *)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_hours_input(hours_str)
  end

  def edit_description_input(description, *)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_description_input(description)
  end

  def handle_edit_pagination_callback(callback_data)
    service = Telegram::Edit::PaginationService.new(controller, current_user)
    page = service.handle_callback(callback_data)
    return unless page

    show_time_shifts_list(page)
  end

  def edit_field_callback_query(field)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_field_selection(field)
  end

  def edit_project_callback_query(project_slug)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_project_selection(project_slug)
  end

  def edit_confirm_callback_query(action)
    service = Telegram::Edit::TimeShiftService.new(controller, current_user)
    service.handle_confirmation(action)
  end
end
