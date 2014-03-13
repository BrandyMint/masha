class MoneyOutgoing < ActiveRecord::Base
  include Authority::Abilities
  belongs_to :user
  belongs_to :company
  belongs_to :project
  belongs_to :implementer, class_name: 'User'

  validates :company_id, presence: true
  validates :project_id, presence: true
  validates :user_id, presence: true
end
