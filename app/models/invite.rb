# frozen_string_literal: true

# Приглашение пользователя в проект по email или telegram username. Автоматически активируется
# при регистрации пользователя.
class Invite < ApplicationRecord
  include Authority::Abilities

  self.authorizer_name = 'InviteAuthorizer'

  belongs_to :user
  belongs_to :project

  scope :sent_by, ->(user) { where user: user }
  scope :sent_to, ->(user) { where email: user.email }
  scope :sent_to_telegram, ->(username) { where telegram_username: username }

  validates :user, presence: true
  validates :role, presence: true, inclusion: { in: Membership.roles.keys.map(&:to_s) }
  validates :project, presence: true
  validate :email_or_telegram_username_present
  validates :email, email: true, uniqueness: { scope: [:project_id] }, allow_blank: true
  validates :telegram_username, uniqueness: { scope: [:project_id] }, allow_blank: true

  def self.activate_for(user)
    invites = sent_to(user)
    return if invites.blank?

    invites.each do |i|
      i.project.memberships.create(user: user, role: i.role)
    end
    invites.destroy_all
  end

  def self.activate_for_telegram_user(telegram_user)
    return if telegram_user.username.blank?

    invites = sent_to_telegram(telegram_user.username)
    return if invites.blank?

    # Create user if not exists
    user = telegram_user.user || User.create!(telegram_user: telegram_user)

    invites.each do |i|
      i.project.memberships.create(user: user, role: i.role)
    end

    invites
  end

  private

  def email_or_telegram_username_present
    return unless email.blank? && telegram_username.blank?

    errors.add(:base, 'Email or telegram username must be present')
  end
end
