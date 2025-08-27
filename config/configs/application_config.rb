# frozen_string_literal: true
#defaults: &defaults
  #github_repo: https://github.com/brandymint/masha
  #title: MASHA
  #asset_host: http://masha.brandymint.ru/

  #sidekiq_redis:
    #url: <%= "redis://#{ENV['REDIS_HOST'] || '127.0.0.1'}:6379/3" %>

  #default_url_options: &default_url_options
    #host: masha.brandymint.ru
    #protocol: https

  #mail_from: masha@brandymint.ru

  #telegram_bot_name: MashTimeBot
  #telegram_bot_link: https://t.me/MashTimeBot


# Base class for application config classes
class ApplicationConfig < Anyway::Config
  TELEGRAM_LINK_PREFIX = 'https://t.me/'
  env_prefix :masha
  attr_config(
    title: 'MashTime',
    host: 'localhost',
    protocol: 'https',
    telegram_auth_expiration: 120, # В Секундах
    redis_cache_store_url: 'redis://localhost:6379/2',
    bot_token: '',
    bot_username: '',
    github_client_id: '',
    github_client_secret: '',
    mail_from: ''
  )

  coerce_types(
    telegram_auth_expiration: :integer
  )

  def home_url
    if home_subdomain.present?
      "#{protocol}://#{home_subdomain}.#{host}"
    else
      "#{protocol}://#{host}"
    end
  end

  def bot_url
    TELEGRAM_LINK_PREFIX + bot_username
  end

  def bot_id
    bot_token.split(':').first
  end

  def default_url_options
    { host: , protocol: }
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
