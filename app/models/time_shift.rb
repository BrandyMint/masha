class TimeShift < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  scope :ordered, -> { order 'date desc' }

  validates :project, :presence => true
  validates :user, :presence => true
  validates_date :date, :on_or_before => lambda { Date.today }
  validates :hours, :presence => true, :numericality => { :greater_than_or_equal_to => 0.1, :less_than_or_equal_to => 24 }
  validates :description, :presence => true, :uniqueness => { :scope => [:project_id, :user_id, :date, :hours] }
end
