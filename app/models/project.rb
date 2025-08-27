# frozen_string_literal: true

class Project < ApplicationRecord
  include Authority::Abilities
  extend FriendlyId

  friendly_id :name, use: :slugged

  # belongs_to :owner, class_name: 'User'

  has_many :time_shifts
  has_many :timed_projects, through: :time_shift, class_name: 'Project'

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invites

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(active: true) }
  scope :alive, -> { where(active: true) }
  scope :archive, -> { where(active: false) }

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9._+-]+\Z/, message: "can't be blank. Characters can only be [a-z 0-9 . - +]" }

  before_validation on: :create do
    self.slug = Russian.translit(name.to_s).squish.parameterize if slug.blank?
  end

  # active_admin в упор не видит friendly_id-шный slug
  def to_param
    id.to_s
  end

  def to_s
    slug
  end

  def roles_of_user(user)
    applied_roles.select { |r| r.user == user }
  end

  def activate
    update_attribute(:active, true)
  end

  def archivate
    update_attribute(:active, false)
  end
end
