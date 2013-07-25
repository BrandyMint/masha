class InviteMailer < ActionMailer::Base
	include ApplicationHelper

  def new_invite_email (invite)
  	@invite = invite
  	@role = role_human @invite.role
	  mail(cc: @invite.email, subject: t('new_invite', :project => @invite.project.name) )
  end

end
