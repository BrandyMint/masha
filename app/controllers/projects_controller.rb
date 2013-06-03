class ProjectsController < ApplicationController
  inherit_resources

  custom_actions :set_role => :post, :remove_role => :delete

  def set_role
    User.find(params[:user_id]).set_role params[:role], resource
    redirect_to :back
  end

  def remove_role
    User.find(params[:user_id]).membership_of(resource).try :destroy
    redirect_to :back
  end

  protected

  def permitted_params
    params.permit :project => [:name, :slug]
  end

  def collection
    if current_user.is_root?
      @projects = Project.ordered
    else
      @projects = current_user.available_projects
    end
  end
end
