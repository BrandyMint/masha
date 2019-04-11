class ApplicationController < ActionController::Base
  class NotLogged < StandardError
  end
  include ApplicationHelper

  before_action :define_page_title
  after_action :check_email_existence

  protect_from_forgery with: :exception if Rails.env.production?

  helper_method :current_user, :logged_in?, :admin_namespace?, :home_url
  helper :all

  rescue_from NotLogged, with: :handle_not_authorized_error

  # TODO Тут нужно кидать на страницу где написано нет доступа
  # Потому что если кидать на страницу логина, а пользователь залогинен
  # то его кинет обратно и будет цикл
  # rescue_from CanCan::AccessDenied, :with => :handle_no_access
  # rescue_from ActiveRecord::RecordNotFound, :with => :error_not_found

  private

  def check_email_existence
    if logged_in? && current_user.email.blank?
      flash[:alert] = t('no_email', url: edit_profile_path).html_safe
    end
  end

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
    @page_title = Settings.title + ' - ' + t(action_name, scope: [:titles, controller_name], default: 'Учет в кармане')
  end

  def handle_not_authorized_error
    show_login_form 401
  end

  # Forbidden
  #
  def handle_no_access
    show_login_form 403
  end

  def show_login_form(status)
    # чтобы не выводить дублирующую форму логина в заголовке
    # @login_process = true
    # @session = Session.new :backurl => request.url

    gflash :now, error: 'Нет доступа к запрашиваемому ресурсу.'
    respond_to do |format|
      format.html { render 'sessions/new', layout: 'application', status: status }
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
    unless logged_in?
      session[:return_to_url] = request.url && request.get?

      fail NotLogged
    end
  end

  def authenticate_admin!
    redirect_to root_path unless current_user && current_user.is_root?
  end
end
