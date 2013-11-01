class InviteService

  attr_reader :invite

  def initialize project, invite_params
    @project = project
    @invite_params = invite_params
    @invite = nil
  end

  def make_invite success: nil, failure: nil
    @invite = @project.invites.where(email: @invite_params[:email]).first

    binding.pry

    if @invite.present?

      # Отправляем повторно email, раз просят
      InviteMailer.new_invite_email(@invite).deliver

      success.call
    else
      @invite = @project.invites.build @invite_params

      if @invite.save
        InviteMailer.new_invite_email(@invite).deliver
        success.call
      else
        failure.call
      end
    end
  end

end
