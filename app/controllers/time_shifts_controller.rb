# frozen_string_literal: true

class TimeShiftsController < ApplicationController
  before_action :require_login
  inherit_resources

  def summary
    @time_sheet_form = TimeSheetForm.build_from_params params[:time_sheet_form]

    template = 'summary'

    respond_to do |format|
      format.xlsx { render xlsx: template }
      format.csv  { send_data build_summary.to_csv }
      format.html { render action: template, locals: { result: build_summary } }
    end
  end

  def index
    if viewable_projects_collection.empty?
      render 'no_projects'
    else
      @time_sheet_form = TimeSheetForm.build_from_params params[:time_sheet_form]
      return render 'blank', locals: { result: build_summary } if params[:time_sheet_form].blank?
      return render 'empty' unless @time_sheet_form.valid?

      template = 'index'
      query = TimeSheetQuery.new @time_sheet_form

      query.available_projects = current_user.available_projects
      query.available_users = current_user.available_users
      query.perform

      respond_to do |format|
        format.xlsx { render xlsx: template, locals: { result: query } }
        format.csv  { send_data query.to_csv }
        format.html { render action: template, locals: { result: query } }
      end
    end
  end

  def show
    redirect_to time_shifts_url
  end

  def new
    @time_shift = TimeShift.new default_time_shift_form
    render layout: 'static'
  end

  def edit
    @time_shift = TimeShift.find params[:id]
    authorize_action_for(@time_shift)
  end

  def create
    super do |success, _error|
      success.html do
        redirect_to new_time_shift_url,
                    flash: { notice: t('flash.time_shift_addition', hours: human_hours(@time_shift.hours), project: @time_shift.project,
                                                                    date: l(@time_shift.date)) }
      end
    end
  end

  def destroy
    @time_shift = TimeShift.find params[:id]
    authorize_action_for(@time_shift)
    @time_shift.destroy

    redirect_to time_shifts_url
  end

  private

  def build_summary
    SummaryQuery.for_user(
      current_user,
      period: params[:period] || 'week',
      group_by: params[:group_by]
    )
                .list_by_days
  end

  def default_time_shift_form
    selected_project = get_project_id_from_params
    {
      project_id: selected_project || current_user.time_shifts.order(:id).last.try(:project_id),
      date: Time.zone.today
    }
  end

  def get_project_id_from_params
    permitted_params
    return unless params[:time_shift][:project_id]

    project = Project.where(id: params[:time_shift][:project_id]).first
    project.id if current_user.membership_of(project)
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
