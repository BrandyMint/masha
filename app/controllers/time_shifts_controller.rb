class TimeShiftsController < ApplicationController
  before_filter :require_login
  inherit_resources

  def index
    if viewable_projects_collection.empty?
      render 'no_projects'
    else
      @time_sheet_form = TimeSheetForm.new params[:time_sheet_form]
      if @time_sheet_form.empty?

        # Отправили пустую форму
        if params[:time_sheet_form].present?
          render 'empty'
        else
          query = SummaryQuery.new

          # TODO Устанвливать доступные проекты исходя их уровня доступа
          query.available_projects = current_user.available_projects
          query.available_users = current_user.available_users
          query.perform

          @summary = query
          render 'summary'
        end
      else
        query = TimeSheetQuery.new @time_sheet_form

        # TODO Устанвливать доступные проекты исходя их уровня доступа
        query.available_projects = current_user.available_projects
        query.available_users = current_user.available_users

        @groups = query.perform
      end
    end
  end

  def create
    super do |success, error|
      success.html {
        redirect_to new_time_shift_url, :notice => t('time_shift_addition', :hours => human_hours(@time_shift.hours), :project => @time_shift.project, :date => l(@time_shift.date))
      }
    end
  end

  def new
    @time_shift = TimeShift.new default_time_shift_form
  end

  def destroy
    @time_shift = TimeShift.find params[:id]
    authorize_action_for(@time_shift)
    @time_shift.destroy

    redirect_to time_shifts_url
  end

  def edit
    @time_shift = TimeShift.find params[:id]
    authorize_action_for(@time_shift)
  end

  def show
    redirect_to time_shifts_url
  end

  protected

  def default_time_shift_form
    selected_project = get_project_id_from_params
    {
      :project_id => selected_project ? selected_project : current_user.time_shifts.order(:id).last.try(:project_id),
      :date => Date.today
    }
  end

  def get_project_id_from_params
    permitted_params
    if params[:time_shift][:project_id]
      project = Project.where(:id => params[:time_shift][:project_id]).first
      project.id if current_user.membership_of(project)
    end
  end

  def permitted_params
    # TODO Проверить что проект разрешен для добавления времени
    params[:time_shift] ||= {}
    params[:time_shift][:user_id] = current_user.id # unless current_user.is_root?
    params[:time_shift][:project_id] ||= nil
    params.require(:time_shift).permit!

    params
  end
end
