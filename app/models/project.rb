class Project < ActiveRecord::Base
  include Authority::Abilities
  extend FriendlyId

  ROLES = Membership::ROLES

  friendly_id :name, use: :slugged

  belongs_to :owner, :class_name => 'User'

  has_many :time_shifts
  has_many :timed_projects, :through => :time_shift, :class_name => 'Project'

  has_many :memberships
  has_many :users, :through => :memberships

  scope :ordered, -> { order(:name) }

  validates :name, :presence => true, :uniqueness => true
  validates :slug, :presence => true, :uniqueness => true

  # active_admin в упор не видит friendly_id-шный slug
  def to_param
    id
  end

  def to_s
    name
  end

  def roles_of_user user
    applied_roles.select { |r| r.user==user }
  end
end
