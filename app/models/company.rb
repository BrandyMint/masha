class Company < ActiveRecord::Base
  belongs_to :owner, class_name: 'User'

  validates :name, uniqueness: { scope: [:owner_id] }
end
