# frozen_string_literal: true

class Authentication < ApplicationRecord
  belongs_to :user

  serialize :auth_hash

  scope :by_provider, ->(provider) { where(provider: provider) }

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.providers
    @providers ||= Authentication.group(:provider).order(:provider).pluck(:provider).map(&:to_sym)
  end

  def email
    auth_hash['info']['email']
  rescue StandardError
    '-'
  end

  def url
    if provider == 'telegram'
      "https://t.me/#{nickname}"
    else
      auth_hash
        .dig('extra', 'raw_info', 'url')
    end
  end

  def html_url
    auth_hash.dig 'extra', 'raw_info', 'html_url'
  end

  def nickname
    auth_hash.dig('info', 'nickname') || 'unknown nickname'
  end

  def username
    auth_hash.dig('info', 'name') || 'unknown username'
  end
end
