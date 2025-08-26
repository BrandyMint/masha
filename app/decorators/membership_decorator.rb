# frozen_string_literal: true

class MembershipDecorator < Draper::Decorator
  delegate_all
  decorates_association :user

  delegate :name, to: :user
  delegate :avatar, to: :user
  delegate :name_as_link, to: :user

  def telegram_link
    auth = object.authentications.by_provider(:telegram).take
    if auth
      h.link_to "@#{auth.nickname}", auth.url
    else
      h.content_tag :span, 'Телеграм не привязан', class: 'label label-default'
    end
  end

  def remove_link
    return unless object.project.active && h.current_user.can_delete?(object)

    h.link_to h.project_membership_path(object.project, object),
              data: { method: :delete, confirm: I18n.t('memberships.delete.confirm') } do
      h.ficon 'cancel-1', color: :gray, size: 18
    end
  end
end
