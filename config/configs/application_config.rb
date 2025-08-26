# frozen_string_literal: true

# Base class for application config classes
class ApplicationConfig < Anyway::Config
  TELEGRAM_LINK_PREFIX = "https://t.me/"
  env_prefix :masha
  env_prefix :vilna
  attr_config(
    host: "localhost",
    protocol: "https",
    telegram_auth_expiration: 120, # В Секундах
    redis_cache_store_url: "redis://localhost:6379/2",
    bot_token: "",
    bot_username: "",
  )

  coerce_types(
    telegram_auth_expiration: :integer
  )

  def home_url
    if home_subdomain.present?
      protocol + "://" + home_subdomain + "." + host
    else
      protocol + "://" + host
    end
  end

  def bot_url
    TELEGRAM_LINK_PREFIX + bot_username
  end

  def bot_id
    bot_token.split(":").first
  end

  class << self
    # Make it possible to access a singleton config instance
    # via class methods (i.e., without explicitly calling `instance`)
    delegate_missing_to :instance

    private

    # Returns a singleton config instance
    def instance
      @instance ||= new
    end
  end
end
