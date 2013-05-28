class ProjectsController < ApplicationController
  inherit_resources

  protected

  def begin_of_association_chain
    current_user
  end

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
