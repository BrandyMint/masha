class Settings < Settingslogic
  source "#{Rails.root}/config/settings.yml"
  namespace Rails.env

  suppress_errors Rails.env.production?

  Rails.configuration.action_mailer.merge!(action_mailer.symbolize_keys)
end
