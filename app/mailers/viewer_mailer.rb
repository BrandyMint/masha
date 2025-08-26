# frozen_string_literal: true

class ViewerMailer < ApplicationMailer
  def new_time_shift_email(time_shift)
    @human_hours = human_hours(time_shift.hours)
    @human_date = l(time_shift.date)
    @time_shift = time_shift

    emails = supervisors_emails_of_project(@time_shift.project)
    emails.delete(@time_shift.user.email)

    return if emails.blank?

    mail(cc: emails,
         subject: t('time_shift_addition', hours: @human_hours, project: @time_shift.project,
                                           date: @human_date))
  end
end
