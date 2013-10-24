class PasswordResetsController < ApplicationController
  skip_before_filter :require_login

  def create
    @user = User.find_by_email(params[:password_reset_form][:email])
    @user.deliver_reset_password_instructions! if @user
    redirect_to(new_session_path, :notice => t('devise.passwords.send_paranoid_instructions'))
  end

  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]

    if @user.blank?
      not_authenticated
      return
    end

    @password_form = PasswordResetForm.new
    @password_form.email = @user.email
  end

  def update
    @token = params[:token]
    @user = User.load_from_reset_password_token(params[:token])

    if @user.blank?
      not_authenticated
      return
    end

    @password_form = PasswordResetForm.new(permitted_params)

    if @password_form.valid?
      @user.change_password!(@password_form.password)
      login @user.email, @password_form.password
      redirect_to time_shifts_path, :notice => t('devise.passwords.updated')
    else
      render :action => "edit"
    end
  end

  private

  def permitted_params
    params.require(:password_reset_form).permit(:email, :password, :password_confirmation)
  end
end