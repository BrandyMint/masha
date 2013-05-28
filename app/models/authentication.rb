class Authentication < ActiveRecord::Base
  belongs_to :user

  validate :provider, :presence => true
  validate :uid, :presence => true
end
