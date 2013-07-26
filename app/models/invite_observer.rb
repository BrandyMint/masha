class InviteObserver < ActiveRecord::Observer

	def after_save(invite)
		InviteMailer.new_invite_email(invite).deliver
	end
end
