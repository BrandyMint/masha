class ViewerMailer < ActionMailer::Base
	include ApplicationHelper

  def new_time_shift_email (time_shift)
  	@hours = human_hours(time_shift.hours)
  	@time_shift = time_shift

  	emails = supervisors_emails_of_project(@time_shift.project)

	  mail(to: emails, subject: t('time_shift_addition', :hours => @hours, :project => @time_shift.project) ) unless emails.blank?
  end

end
