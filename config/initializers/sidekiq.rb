# frozen_string_literal: true

require 'sidekiq'
Sidekiq.default_worker_options = { 'backtrace' => true }

if Rails.env.production? || Rails.env.include?('staging') || ENV['SIDEKIQ_ASYNC']
  puts 'SIDEKIQ async mode'

  Sidekiq.configure_server do |config|
    config.redis = Settings.sidekiq_redis.symbolize_keys
    config.error_handlers << proc do |ex, context|
      Bugsnag.notify ex do |b|
        b.meta_data = context
      end
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = Settings.sidekiq_redis.symbolize_keys
  end

elsif Rails.env.development?
  puts 'SIDEKIQ inline mode'

  require 'sidekiq/testing/inline'
  Sidekiq::Testing.inline!

elsif Rails.env.test?
  require 'sidekiq/testing/inline'
  Sidekiq::Testing.fake!

  Sidekiq.configure_server do |config|
    config.redis = Settings.sidekiq_redis.symbolize_keys
  end
  Sidekiq.configure_client do |config|
    config.redis = Settings.sidekiq_redis.symbolize_keys
  end
else

  raise "Not supported env #{Rails.env}"
end

Sidekiq::Logging.logger = ActiveSupport::Logger.new Rails.root.join './log/sidekiq.log'
