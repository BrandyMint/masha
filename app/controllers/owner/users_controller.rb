class Owner::UsersController < Owner::BaseController
  authorize_actions_for User

  inherit_resources

  def edit
    @projects = Project.all
    super
  end

  def show
    redirect_to users_url
  end

  private

  def permitted_params
    params.permit :user => [:name, :is_root]
  end

  def project
    @project ||= Project.find params[:project_id]
  end
end
