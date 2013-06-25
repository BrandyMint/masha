class Authentication < ActiveRecord::Base
  belongs_to :user

  serialize :auth_hash

  scope :by_provider, lambda { |provider| where(:provider => provider) }

  validate :provider, :presence => true
  validate :uid, :presence => true, :uniqueness => { :scope => :provider }

  def self.providers
    @providers ||= Authentication.group(:provider).order(:provider).pluck(:provider).map { |p| p.to_sym }
  end

  def email
    auth_hash['info']['email']
  rescue
    '-'
  end

  def nickname
    auth_hash['info']['nickname']
  rescue
    '-'
  end

  def username
    auth_hash['info']['name']
  rescue
    '-'
  end
end
