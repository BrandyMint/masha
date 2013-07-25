class MembershipDecorator < Draper::Decorator
  delegate_all

  def remove_link
    if h.current_user.can_delete?(source) && source.user != h.current_user
      h.link_to h.project_membership_path(source.project, source), :data => { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') } do
        h.icon :remove
      end
    end
  end
end
