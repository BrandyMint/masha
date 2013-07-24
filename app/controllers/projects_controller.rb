class ProjectsController < ApplicationController
  before_filter :require_login
  inherit_resources

  def index
    @project = Project.new
    super
  end

  def new
    @project = Project.new
  end

  def create
  	@project = Project.new(permited_params)

    if @project.save
      current_user.set_role :owner, @project
      redirect_to new_time_shift_url(:time_shift => { :project_id => @project.id }), :notice => t(:project_created, :project => @project.name)
    else
      render :new
    end
  end

  def show
    redirect_to new_time_shift_url(:time_shift => { :project_id => params[:id] })
  end

  protected

  def collection
    @projects = current_user.projects.ordered
  end

  def permited_params
    params.require(:project).permit(:name, :slug, :description)
  end
end
