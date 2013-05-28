class ProjectsController < ApplicationController
  inherit_resources

  def permitted_params
    params.permit :project => [:name, :slug]
  end

  def collection
    if current_user.has_role? :admin
      @projects = Project.ordered
    else
      @projects = current_user.available_projects
    end
  end
end
