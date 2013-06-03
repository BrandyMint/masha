class TimeShiftsController < ApplicationController
  inherit_resources

  protected

  def collection
    if current_user.is_root?
      @time_shifts = TimeShift.ordered.includes(:project, :user)
    else
      @time_shifts = current_user.time_shifts.ordered.includes(:project, :user)
    end
  end
end
