# frozen_string_literal: true

Masha::Application.configure do
  config.action_controller.perform_caching = true
  config.active_support.deprecation = :notify
  config.assets.compile = true
  config.assets.digest = true
  config.assets.version = '1.0'
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_formatter = Logger::Formatter.new
  config.log_level = :info
  config.serve_static_assets = true
end
