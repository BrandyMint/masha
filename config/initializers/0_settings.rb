class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env

  suppress_errors Rails.env.production?

  Rails.configuration.action_mailer.merge!(action_mailer.symbolize_keys)
end

class Settings::Omniauth < Settingslogic
  source "#{Rails.root}/config/omniauth.yml"
  namespace Rails.env
  suppress_errors Rails.env.production?
end
