# frozen_string_literal: true

module Owner
  class ProjectsController < Owner::BaseController
    inherit_resources

    custom_actions set_role: :post, remove_role: :delete

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
      params.permit project: %i[name slug]
    end

    def collection
      @projects = if current_user.is_root?
                    Project.ordered
                  else
                    current_user.projects.ordered
                  end
    end
  end
end
