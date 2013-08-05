class ApplicationController < ActionController::Base
  class NotLogged < StandardError

  end
  include ApplicationHelper

  after_filter :check_email_existence

  protect_from_forgery with: :exception if Rails.env.production?

  helper_method :current_user, :logged_in?, :admin_namespace?

  helper :all

  rescue_from NotLogged, :with => :handle_not_authorized_error

  # TODO Тут нужно кидать на страницу где написано нет доступа
  # Потому что если кидать на страницу логина, а пользователь залогинен
  # то его кинет обратно и будет цикл
  #rescue_from CanCan::AccessDenied, :with => :handle_no_access
  #rescue_from ActiveRecord::RecordNotFound, :with => :error_not_found

  private 

  def handle_not_authorized_error
    show_login_form 401
  end

  # Forbidden
  #
  def handle_no_access
    show_login_form 403
  end

  def show_login_form status
    # чтобы не выводить дублирующую форму логина в заголовке
    #@login_process = true
    #@session = Session.new :backurl => request.url

    respond_to do |format|
      format.html { render 'sessions/new', :layout => 'application', :status => status }
      # Иначе при не авторизованном запросе /posts/16370.pdf падает при поиске sessions/new.pdf
      # https://dapi.airbrake.io/errors/31803485
      #
      #format.any { redirect_to no_access_url(:backurl=>current_url) }
    end
  end

  def admin_namespace?
    @namespace ||= :default
    @namespace == :admin
  end

  def require_login
    if !logged_in?
      session[:return_to_url] = request.url && request.get?

      raise NotLogged
    end
  end

  def authenticate_admin!
    redirect_to root_path unless current_user && current_user.is_root?
  end
end
