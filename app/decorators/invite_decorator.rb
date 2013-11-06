class InviteDecorator < Draper::Decorator
  delegate_all

  def remove_link
    if h.current_user.can_delete?(source)
      h.link_to h.invite_path(source), :data => { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') } do
        h.ficon 'cancel-1', color: :gray, size: 18
      end
    end
  end
end
