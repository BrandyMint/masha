# Auth Hash Schema
# https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
#
module Authentificator
end

class Authentificator::Base
  attr_accessor :auth_hash, :user

  def self.authentificate(auth_hash)
    new(auth_hash).authentificate
  end

  def initialize(_auth_hash)
    @auth_hash = _auth_hash
    @user = nil
  end

  def authentificate
    find(provider, uid) || find_by_email || create
  end

  def find_by_email
    return nil unless email.present?

    # TODO Предусмотреть факт неподтвержденности емайла
    @user = User.where(email: email).first

    return nil unless @user.present?

    add_authentication @user

    update_user_info @user if @user.present?

    @user
  end

  def find(_prov, _uid)
    auth = Authentication.where(provider: _prov, uid: _uid).first

    return nil unless auth.present?

    auth.update_attribute :auth_hash, auth_hash

    auth.update_attribute :user, create_user unless auth.user.present?

    update_user_info auth.user if auth.user.present?

    auth.user
  end

  def create
    User.transaction do
      @user = create_user
      add_authentication @user
    end

    update_user_info @user if @user.present?

    @user
  end

  private

  def add_authentication(user)
    user.authentications.create do |a|
      a.provider = provider
      a.uid = uid
      a.auth_hash = auth_hash
    end
  end

  def update_user_info(user)
    [:nickname, :email].each do |key|
      unless user.read_attribute(key).present?
        begin
          user.update_attribute key, auth_hash['info'][key.to_s]
        rescue ActiveRecord::RecordNotUnique => err
          Bugsnag.notify err
          user.reload!
        end
      end
    end
  end

  def create_user
    User.create! do |u|
      u.name = user_name
      u.nickname = nickname
      u.email = email
    end
  end

  def nickname
    auth_hash['info']['nickname']
  end

  def user_name
    name = auth_hash['info']['name']

    name.blank? ? nickname : name
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
