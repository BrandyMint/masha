# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  skip_before_action :require_login, raise: false

  def new
    @email_form = EmailForm.new
  end

  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]

    if @user.blank?
      not_authenticated
      return
    end
    @password_form = PasswordChangeForm.new
  end

  def create
    @email_form = EmailForm.new params.expect(email_form: [:email])

    if @email_form.valid?
      user = User.find_by(email: params[:email_form][:email])
      user.deliver_reset_password_instructions!
      redirect_to(new_session_path, flash: { notice: t('devise.passwords.send_instructions') })
    else
      render :new
    end
  end

  def update
    @token = params[:token]
    @user = User.load_from_reset_password_token(params[:token])

    if @user.blank?
      not_authenticated
      return
    end

    @password_form = PasswordChangeForm.new(permitted_params)

    if @password_form.valid?
      @user.change_password!(@password_form.password)
      login @user.email, @password_form.password
      redirect_to(time_shifts_path, flash: { notice: t('devise.passwords.updated') })
    else
      render action: 'edit'
    end
  end

  private

  def permitted_params
    params.expect(password_change_form: [:password, :password_confirmation])
  end
end
