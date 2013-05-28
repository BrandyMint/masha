class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  source "#{Rails.root}/config/application.local.yml"
  namespace Rails.env

  suppress_errors Rails.env.production?

  Rails.configuration.action_mailer.merge!(self.action_mailer.symbolize_keys)
end
