class PasswordResetsController < ApplicationController
  skip_before_filter :require_login
  def new
    @email_form = EmailForm.new
  end

  def create
    @email_form = EmailForm.new params.require(:email_form).permit(:email)

    if @email_form.valid?
      user = User.find_by_email(params[:email_form][:email])
      user.deliver_reset_password_instructions!
      redirect_to(new_session_path, gflash: { notice: t("devise.passwords.send_instructions") })
    else
      render :new
    end
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
      redirect_to time_shifts_path, gflash: { notice: t("devise.passwords.updated") }))
    else
      render :action => "edit"
    end
  end

  private

  def permitted_params
    params.require(:password_change_form).permit(:password, :password_confirmation)
  end
end
