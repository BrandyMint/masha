class WelcomeController < ApplicationController
  layout 'welcome'

  def index
    if current_user.present?
      redirect_to time_shifts_url
    end
  end
end
