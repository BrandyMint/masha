class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper

  default from: Settings.mail_from

  self.default_url_options = Settings.default_url_options.symbolize_keys
end
