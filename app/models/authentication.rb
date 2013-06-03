class Authentication < ActiveRecord::Base
  belongs_to :user

  scope :by_provider, lambda { |provider| where(:provider => provider) }

  validate :provider, :presence => true
  validate :uid, :presence => true, :uniqueness => { :scope => :provider }

  def self.providers
    @providers ||= Authentication.group(:provider).order(:provider).pluck(:provider).map { |p| p.to_sym }
  end
end
