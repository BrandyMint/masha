# frozen_string_literal: true

class InviteDecorator < Draper::Decorator
  delegate_all

  def remove_link
    return unless h.current_user.can_delete?(object)

    h.link_to h.invite_path(object), data: { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') } do
      h.ficon 'cancel-1', color: :gray, size: 18
    end
  end
end
