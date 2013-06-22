# Auth Hash Schema
# https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
#
module Authentificator
end

class Authentificator::Base
  attr_accessor :auth_hash, :user

  def self.authentificate auth_hash
    new(auth_hash).authentificate
  end

  def initialize _auth_hash
    @auth_hash = _auth_hash
    @user = nil
  end

  def authentificate
    find || create
  end

  def find
    auth = Authentication.where(:provider => provider, :uid => uid).first

    return nil unless auth.present?

    auth.update_attribute :auth_hash, @auth_hash

    auth.update_attribute :user, create_user unless auth.user.present?

    return auth.user
  end

  def create
    User.transaction do
      @user = create_user

      @user.authentications.create do |a|
        a.provider = provider
        a.uid = uid
        a.auth_hash = @auth_hash
      end
    end

    @user
  end

  private 

  def create_user
    User.create do |u|
      u.name = info.name
    end
  end

  def info
    @info ||= OpenStruct.new auth_hash['info']
  end

  def provider
    auth_hash['provider']
  end

  def uid
    auth_hash['uid']
  end
end
