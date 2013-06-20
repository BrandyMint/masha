class ApplicationController < ActionController::Base
  class NotLogged < StandardError

  end
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception if Rails.env.production?

  helper_method :current_user, :logged_in?, :admin_namespace?

  helper :all

  include ApplicationHelper

  def current_user
    @current_user ||= User.find session[:user_id] if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    self.current_user = nil
  end

  def logout
    current_uset=nil
  end

  def logged_in?
    !!current_user
  end

  def auto_login user
    self.current_user= user
  end

  def current_user= user
    @current_user= user
    if user.present?
      session[:user_id] = user.id
    else
      session[:user_id] = nil
    end
  end

  private 

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
end
