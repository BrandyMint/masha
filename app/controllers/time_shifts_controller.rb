class TimeShiftsController < ApplicationController
  before_filter :require_login
  inherit_resources

  def summary
    @time_sheet_form = TimeSheetForm.build_from_params params[:time_sheet_form]

    template = 'summary'
    @result = build_summary

    respond_to do |format|
      format.xlsx { render xlsx: template }
      format.csv  { send_data @result.to_csv }
      format.html { render action: template }
    end
  end

  def index
    if viewable_projects_collection.empty?
      render 'no_projects'
    else
      @time_sheet_form = TimeSheetForm.build_from_params params[:time_sheet_form]
      if params[:time_sheet_form].present?
        if @time_sheet_form.valid?
          template = 'index'
          query = TimeSheetQuery.new @time_sheet_form
        else
          return render 'empty'
        end
      else
        @result = build_summary
        return render 'blank'
      end

      query.available_projects = current_user.available_projects
      query.available_users = current_user.available_users
      query.perform

      @result = query
      respond_to do |format|
        format.xlsx { render xlsx: template }
        format.csv  { send_data @result.to_csv }
        format.html { render action: template }
      end
    end
  end

  def create
    super do |success, _error|
      success.html do
        redirect_to new_time_shift_url, gflash: { notice: t('gflash.time_shift_addition', hours: human_hours(@time_shift.hours), project: @time_shift.project, date: l(@time_shift.date)) }
      end
    end
  end

  def new
    @page_header_type = :static
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

  private

  def build_summary
    query = SummaryQuery.new params[:period]

    query.available_projects = current_user.available_projects
    query.available_users = current_user.available_users
    query.group_by = params[:group_by]
    query.perform

    query
  end

  def default_time_shift_form
    selected_project = get_project_id_from_params
    {
      project_id: selected_project ? selected_project : current_user.time_shifts.order(:id).last.try(:project_id),
      date: Date.today
    }
  end

  def get_project_id_from_params
    permitted_params
    if params[:time_shift][:project_id]
      project = Project.where(id: params[:time_shift][:project_id]).first
      project.id if current_user.membership_of(project)
    end
  end

  def permitted_params
    # TODO: Check that the project is allowed to add time
    params[:time_shift] ||= {}
    params[:time_shift][:user_id] = current_user.id if action_name != 'update'
    params[:time_shift][:project_id] ||= nil
    params.require(:time_shift).permit!
    params
  end
end
