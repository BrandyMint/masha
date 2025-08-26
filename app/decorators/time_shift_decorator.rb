# frozen_string_literal: true

class TimeShiftDecorator < Draper::Decorator
  delegate_all

  def tr_class
    if object.updated_at != object.created_at
      :warning
    elsif object.updated_at > Time.zone.now - 1.minute
      :success
    end
  end

  def date
    h.human_date object.date
  end

  def user
    h.link_to object.user, h.url_for(time_sheet_form: time_sheet_form.merge(user_id: user_id))
  end

  def project
    h.link_to object.project, h.url_for(time_sheet_form: time_sheet_form.merge(project_id: project_id))
  end

  def description
    h.auto_link CGI.h(object.description), html: { target: '_blank' }
  end

  def update_link(args = {})
    args[:css_class] ||= ''
    return unless h.current_user.can_update?(object)

    h.link_to h.edit_time_shift_path(object), class: args[:css_class] do
      h.ficon 'edit', color: 'gray-light', size: 16
    end
  end

  def remove_link
    return unless object.persisted?

    return unless h.current_user.can_delete?(object)

    h.link_to 'Удалить',
              h.time_shift_path(object),
              class: 'btn btn-link btn-small icon-color-red', data: { method: :delete, confirm: I18n.t('time_shifts.delete.confirm') }
  end

  private

  def time_sheet_form
    h.params.fetch(:time_sheet_form, {}).permit!.to_h || {}
  end
end
