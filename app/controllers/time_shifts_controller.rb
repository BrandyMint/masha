class TimeShiftsController < ApplicationController
  before_filter :require_login
  inherit_resources

  def index
    @time_sheet_form = TimeSheetForm.new params[:time_sheet_form]

    query = TimeSheetQuery.new @time_sheet_form

    # TODO Устанвливать доступные проекты исходя их уровня доступа
    query.available_projects = current_user.available_projects
    query.available_users = current_user.available_users

    @groups = query.perform
  end

  def create
    super do |success, error|
      success.html {
        redirect_to :time_shifts, :notice => "Добавили #{human_hours @time_shift.hours} в #{@time_shift.project}"
      }
    end
  end

  def new
    @time_shift = TimeShift.new default_time_shift_form
  end

  protected

  def default_time_shift_form
    {
      :project_id => current_user.time_shifts.order(:id).last.try(:project_id),
      :date => Date.today
    }
  end

  def permitted_params
    # TODO Проверить что проект разрешен для добавления времени
    params[:time_shift] ||= {}
    params[:time_shift][:user_id] = current_user.id # unless current_user.is_root?
    params.require(:time_shift).permit!

    params
  end
end
