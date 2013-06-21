class TimeShiftsController < ApplicationController
  inherit_resources

  def index
    @time_sheet_form = TimeSheetForm.new params[:time_sheet_form]

    query = TimeSheetQuery.new @time_sheet_form

    # TODO Устанвливать доступные проекты исходя их уровня доступа
    query.available_projects = current_user.projects unless current_user.is_root?
    query.available_users = [current_user] unless current_user.is_root?

    @groups = query.perform
  end

  def create
    super do |success, error|
      success.html {
        redirect_to :back, :notice => "Добавили #{human_hours @time_shift.hours} в #{@time_shift.project}"
      }
    end
  end

  def new
    @time_shift = TimeShift.new :user_id => current_user.id, :date => Date.today
  end

  protected

  def permitted_params
    # TODO Проверить что проект разрешен для добавления времени
    params[:time_shift] ||= {}
    params[:time_shift][:user_id] = current_user.id unless current_user.is_root?
    params.require(:time_shift).permit!

    params
  end

  def collection
    if current_user.is_root?
      @time_shifts = TimeShift.ordered.includes(:project, :user)
    else
      @time_shifts = current_user.time_shifts.ordered.includes(:project, :user)
    end
  end
end
