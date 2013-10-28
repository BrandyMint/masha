class BaseMailer < ActionMailer::Base
  default Settings.action_mailer.default_options.symbolize_keys
  self.default_url_options = Settings.action_mailer.default_url_options.symbolize_keys
  include ApplicationHelper
end
