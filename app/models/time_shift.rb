class TimeShift < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  scope :ordered, -> { order(:date) }

  validates :project, :presence => true
  validates :user, :presence => true
  validates :date, :presence => true
  validates :hours, :presence => true, :numericality => { :greater_than => 0, :less_than_or_equal_to => 8 }
  validates :description, :presence => true
end
