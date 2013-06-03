class UsersController < ApplicationController
  inherit_resources

  custom_actions :add_role => :post, :remove_role => :delete

  def add_role
    resource.add_role params[:role], project
    redirect_to :back
  end

  def remove_role
    resource.remove_role params[:role], project
    redirect_to :back
  end

  private

  def permitted_params
    params.permit :user => [:name, :is_root]
  end

  def project
    @project ||= Project.find params[:project_id]
  end
end
