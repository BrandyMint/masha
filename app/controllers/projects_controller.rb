class ProjectsController < ApplicationController
  before_filter :require_login
  inherit_resources
  authority_actions activate: 'update', archivate: 'update'

  def index
    @project = Project.new
    @active_projects = current_user.available_projects.active
    @archive_projects = current_user.available_projects.archive
    super
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(permited_params)

    if @project.save
      current_user.set_role :owner, @project
      redirect_to project_memberships_url(@project)
      # new_time_shift_url(:time_shift => { :project_id => @project.id }), :notice => t(:project_created, :project => @project.name)
    else
      render :new
    end
  end

  def show
    redirect_to new_time_shift_url(time_shift: { project_id: params[:id] })
  end

  def edit
    @project = Project.find(params[:id])
    authorize_action_for(@project)
    super
  end

  def update
    @project = Project.find(params[:id])
    authorize_action_for(@project)
    @project.name = permited_params[:name]
    @project.save

    redirect_to project_memberships_url(@project)
  end

  def activate
    @project = Project.find(params[:id])
    authorize_action_for(@project)
    @project.activate
    redirect_to project_memberships_url(@project)
  end

  def archivate
    @project = Project.find(params[:id])
    authorize_action_for(@project)
    @project.archivate
    redirect_to project_memberships_url(@project)
  end

  def destroy
    @project = Project.find(params[:id])
    authorize_action_for(@project)
    @project.destroy

    redirect_to projects_url
  end

  protected

  def collection
    @projects = current_user.projects.ordered
  end

  def permited_params
    params.require(:project).permit(:name, :slug, :description)
  end
end
