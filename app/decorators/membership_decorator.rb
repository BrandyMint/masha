class MembershipDecorator < Draper::Decorator
  delegate_all
  decorates_association :user

  delegate :name, to: :user

  def remove_link
    if h.current_user.can_delete?(source)
      h.link_to h.project_membership_path(source.project, source), :data => { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') } do
        h.icon :remove
      end
    end
  end
end
