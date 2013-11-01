class ApplicationController < ActionController::Base
  class NotLogged < StandardError

  end
  include ApplicationHelper

  after_filter :check_email_existence

  protect_from_forgery with: :exception if Rails.env.production?

  helper_method :current_user, :logged_in?, :admin_namespace?, :home_url

  helper :all

  before_filter :define_page_title

  rescue_from NotLogged, :with => :handle_not_authorized_error

  # TODO Тут нужно кидать на страницу где написано нет доступа
  # Потому что если кидать на страницу логина, а пользователь залогинен
  # то его кинет обратно и будет цикл
  #rescue_from CanCan::AccessDenied, :with => :handle_no_access
  #rescue_from ActiveRecord::RecordNotFound, :with => :error_not_found

  def wiselinks_layout
    _layout.noaccess_path
  end

  private

  def home_url
    if current_user.present?
      if current_user.reporter?
        new_time_shift_url
      else
        time_shifts_url
      end
    else
      root_url
    end
  end

  def define_page_title
    @page_title = Settings.app.title + ' - ' + t( action_name, :scope => [:titles, controller_name], :default => 'Учет в кармане' )
  end

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

    flash.now[:alert] = "Нет доступа к запрашиваемому ресурсу"
    respond_to do |format|
      format.html { render 'sessions/new', :layout => 'application', :status => status }
      # Иначе при не авторизованном запросе /posts/16370.pdf падает при поиске sessions/new.pdf
      # https://dapi.airbrake.io/errors/31803485
      #
      format.any { redirect_to root_url }
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
