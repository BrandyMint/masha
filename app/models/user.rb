# frozen_string_literal: true

# Пользователь системы с OAuth-аутентификацией через GitHub и Telegram. Имеет временные записи,
# участия в проектах, приглашения. Поддерживает роли в проектах и интеграцию с Telegram.
class User < ApplicationRecord
  authenticates_with_sorcery!
  include Authority::UserAbilities
  include Authority::Abilities

  belongs_to :telegram_user, optional: true

  # has_many :owned_projects, class_name: 'Project', foreign_key: :owner_id

  has_many :time_shifts
  has_many :timed_projects, through: :time_shift, class_name: 'Project'

  has_many :authentications, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { joins(:project).where projects: { active: true } }, class_name: 'Membership'
  has_many :active_available_users, through: :active_memberships, source: :available_users
  has_many :available_users, through: :memberships

  has_many :projects, through: :memberships
  has_many :invites
  has_many :member_rates, dependent: :destroy
  has_many :rated_projects, through: :member_rates, source: :project
  has_many :clients, dependent: :destroy

  scope :ordered, -> { order :name }
  # scope :without, -> (user) { where arel_table[:id].not_eq(user.id) }

  validates :nickname, uniqueness: true, allow_blank: true
  validates :pivotal_person_id, uniqueness: true, allow_blank: true, numericality: true
  validates :email, email: true, uniqueness: true, allow_blank: true

  before_save do
    # Если будет пустая строка будет UniqueViolation
    # https://www.honeybadger.io/projects/39754/faults/8870949/notices/10
    self.email = nil if email.blank?
  end

  before_create do
    self.is_root = true if User.count.zero?
  end

  after_save do
    Invite.activate_for self
  end

  # validates :password, :confirmation => true
  # validates :password, :presence => true, :on => :create

  # Пользователь репортер больше чем овнер?
  def reporter?
    # TODO: настраивать в профиле
    memberships.members.count > memberships.count / 2
  end

  def by_provider(prov)
    authentications.by_provider(prov).first
  end

  def find_project(key)
    available_projects.alive.find_by(slug: key)
  end

  def email
    # TODO: change :develop to :email
    authentications.where(provider: :developer).pick(:uid) || read_attribute(:email)
  end

  def membership_of(project)
    memberships.where(project_id: project.id).first unless project.nil?
  end

  def has_role?(role, project)
    membership_of(project).try(:role) == role
  end

  def set_role(role, project)
    member = membership_of(project) || memberships.build(project_id: project.id)

    member.role = role
    member.save!
  end

  def to_s
    telegram_user.present? ? telegram_user.public_name : (email.split.first.presence || "##{id}")
  end

  def avatar_url
    telegram_user.try(:photo_url) || Gravatar.src(email)
  end

  def self.find_or_create_by_telegram_data!(data)
    create_with(locale: I18n.locale)
      .find_or_create_by!(
        telegram_user: TelegramUser.find_or_create_by_telegram_data!(data)
      )
  end

  def self.find_or_create_by_telegram_id!(tid)
    create_with(locale: I18n.locale)
      .find_or_create_by!(
        telegram_user_id: tid
      )
  end

  def self.authenticate_with_telegram(data)
    if defined?(UserSession) && data.is_a?(UserSession)
      yield create_with(locale: I18n.locale).find_or_create_by!(email: data.email)
    else
      yield(
        data.is_a?(String) ? User.find_or_create_by_telegram_id!(data) : User.find_or_create_by_telegram_data!(data),
        nil)
    end
  end

  def available_projects
    projects.ordered
  end

end
