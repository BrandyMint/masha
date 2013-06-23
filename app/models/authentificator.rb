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
    find(provider, uid) || find_by_email || create
  end

  def find_by_email
    return nil unless email.present?

    # TODO Предусмотреть факт неподтвержденности емайла
    @user = User.where(:email=>email).first
    add_authentication @user

    update_user_info @user, auth_hash if @user.present?

    return @user
  end

  def find _prov, _uid
    auth = Authentication.where(:provider => _prov, :uid => _uid).first

    return nil unless auth.present?

    auth.update_attribute :auth_hash, auth_hash

    auth.update_attribute :user, create_user unless auth.user.present?

    update_user_info auth.user

    return auth.user
  end

  def create
    User.transaction do
      @user = create_user
      add_authentication @user
    end

    update_user_info @user, auth_hash if @user.present?

    return @user
  end

  private 

  def add_authentication user
    user.authentications.create do |a|
      a.provider = provider
      a.uid = uid
      a.auth_hash = auth_hash
    end
  end

  def update_user_info user
    [:nickname, :email].each do |key|
      unless user.read_attribute(key).present?
        begin
          user.update_attribute key, auth_hash['info'][key.to_s]
        rescue ActiveRecord::RecordNotUnique
          binding.pry
          user.reload!
        rescue StandardError => err
          binding.pry
        end
      end
    end
  end

  def create_user
    User.create do |u|
      u.name = info.name
    end
  end

  def email
    auth_hash['info']['email']
  end

  def provider
    auth_hash['provider']
  end

  def uid
    auth_hash['uid']
  end
end
