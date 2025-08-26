# frozen_string_literal: true

class WelcomeController < ApplicationController
  layout 'welcome'

  def index
    redirect_to home_url if current_user.present? && !params[:home]
  end
end
