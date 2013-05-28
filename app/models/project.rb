class Project < ActiveRecord::Base
  extend FriendlyId
  resourcify

  ROLES = [:timekeeper, :time_enterer]
  # :owner
  # :admin (global)

  friendly_id :name, use: :slugged

  belongs_to :owner, :class_name => 'User'

  has_many :time_shifts

  scope :ordered, order(:name)

  validates :name, :presence => true, :uniqueness => true
  #validates :slug, :presence => true, :uniqueness => true

  def to_s
    name
  end

  def people
    applied_roles.map &:user
  end

  def roles_of_user user
    applied_roles.select { |r| r.user==user }
  end
end
