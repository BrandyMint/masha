class TimeShiftObserver < ActiveRecord::Observer

	def after_create(time_shift)
		ViewerMailer.new_time_shift_email(time_shift).deliver
	end
end
