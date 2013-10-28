class PasswordResetMailer < BaseMailer
  def reset_password_email(user)
    @user = user
    @url  = edit_password_reset_url(user.reset_password_token)
    mail(
      :to => user.email,
      :subject => t('devise.mailer.reset_password_instructions.subject'),
      :content_type => "text/html"
    )
  end
end
