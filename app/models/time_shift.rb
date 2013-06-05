class TimeShift < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  scope :ordered, -> { order(:date) }

  validates :project, :presence => true
  validates :user, :presence => true
  validates :date, :presence => true
  validates :hours, :presence => true
  validates :description, :presence => true

end
