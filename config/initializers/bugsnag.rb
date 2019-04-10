Bugsnag.configure do |config|
  config.api_key =  Rails.application.credentials.bugsnag_api_key
  config.app_version = AppVersion.format('%M.%m.%p')
  config.notify_release_stages = %w(production staging)
end
