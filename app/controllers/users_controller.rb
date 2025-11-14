# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    @user = User.find params[:id]
    authorize_action_for @user
  end

  def new
    @reg = RegisterForm.new params[:register_form]
  end

  def create
    @reg = RegisterForm.new params[:register_form]

    user = @reg.save
    if user.present?
      login user.email, @reg.password
      redirect_to time_shifts_url, flash: { notice: t('flash.signed_up') }
    else
      render :new
    end
  end
end
