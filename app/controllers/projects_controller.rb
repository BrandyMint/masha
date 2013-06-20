class ProjectsController < ApplicationController
  before_filter :require_login
  inherit_resources

  def show
    redirect_to new_time_shift_url(:time_shift=>{:project_id=>params[:id]})
  end

  protected

  def collection
    @projects = current_user.projects.ordered
  end
end
