class Project < ActiveRecord::Base
  belongs_to :owner

  has_many :time_shifts
end
