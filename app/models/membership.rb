class Membership < ActiveRecord::Base
  include Authority::Abilities
  after_initialize :set_defaults
  self.authorizer_name = 'MembershipAuthorizer'

  scope :last_updates,    -> { order('updated_at desc') }
  scope :viewable,        -> { order 'role_cd < 2' }
  scope :ordered_by_role, -> { order :role_cd }
  scope :owners,          -> { where role_cd: 0 }
  scope :viewers,         -> { where role_cd: 1 }
  scope :members,         -> { where role_cd: 2 }
  scope :supervisors,     -> { where 'role_cd = 0 or role_cd = 1' }
  scope :subscribers,     -> { includes(:user).where users: { subscribed: true } }

  belongs_to :user
  belongs_to :project

  has_many :available_users, through: :project, source: :users

  as_enum :role, owner: 0, viewer: 1, member: 2
  DEFAULT_ROLE = :member

  validates :user_id, uniqueness: { scope: :project_id }

  def set_defaults
    self.role  ||= DEFAULT_ROLE   # will set the default value only if it's nil
  end
end
