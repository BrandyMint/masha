class TimeShiftsController < ApplicationController
  inherit_resources

  def index
    @time_sheet_form = TimeSheetForm.new

    query = TimeSheetQuery.new collection, @time_sheet_form

    @time_shifts = query.perform
  end

  protected

  def collection
    if current_user.is_root?
      @time_shifts = TimeShift.ordered.includes(:project, :user)
    else
      @time_shifts = current_user.time_shifts.ordered.includes(:project, :user)
    end
  end
end
