class TimeShiftDecorator < Draper::Decorator
  delegate_all

  def tr_class
    if source.updated_at != source.created_at
      :warning
    elsif source.updated_at > Time.now - 1.minutes
      :success
    end
  end

  def user
    h.link_to source.user, h.url_for(:time_sheet_form=>time_sheet_form.merge(:user_id=>user_id))
  end

  def project
    h.link_to source.project, h.url_for(:time_sheet_form=>time_sheet_form.merge(:project_id=>project_id))
  end

  def description
    h.auto_link source.description, :html => { :target => '_blank' }
  end

  def update_link
    if h.current_user.can_update?(source)
      h.link_to h.edit_time_shift_path(source) do
        h.ficon 'edit', color: 'gray-light', size: 16
      end
    end
  end

  def remove_link
    if h.current_user.can_delete?(source)
      h.link_to 'Удалить',
        h.time_shift_path(source),
        :class => "btn btn-link btn-small icon-color-red", :data => { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') }
    end
  end

  private

  def time_sheet_form
    h.params[:time_sheet_form] || {}
  end
end
