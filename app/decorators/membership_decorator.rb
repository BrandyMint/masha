class MembershipDecorator < Draper::Decorator
  delegate_all
  decorates_association :user

  delegate :name, to: :user
  delegate :avatar, to: :user

  def remove_link
    if source.project.active and h.current_user.can_delete?(source)
      h.link_to h.project_membership_path(source.project, source), :data => { method: :delete, confirm: I18n.t('memberships.delete.confirm') } do
        h.ficon 'cancel-1', color: :gray, size: 18
      end
    end
  end
end
