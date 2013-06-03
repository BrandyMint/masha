class TimeShift < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  scope :ordered, order(:date)
end
