class InvitesController < ApplicationController

	def create
	end

	def destroy
		@invite = Invite.find params[:id]
		authorize_action_for(@invite)
		@invite.destroy

		redirect_to project_memberships_path(@invite.project)
	end

end
