class Membership < ActiveRecord::Base

  def self.roles_collection
    {'владелец'=>:owner, 'смотритель'=>:viewer, 'участник'=>:member}
  end

  scope :last_updates, -> { order('updated_at desc') }
  belongs_to :user
  belongs_to :project

  as_enum :role, :owner => 0, :viewer => 1, :member => 2

  ROLES = [:owner, :viewer, :member]

  scope :owners,  -> { where :role_cd => 0 }
  scope :viewers, -> { where :role_cd => 1 }
  scope :members, -> { where :role_cd => 2 }

end
