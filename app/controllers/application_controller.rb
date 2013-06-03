class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception if Rails.env.production?

  helper_method :current_user


  def current_user
    @current_user ||= User.find session[:user_id] if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    self.current_user = nil
  end

  def logout
    current_uset=nil
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

end
