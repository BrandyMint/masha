# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper

  default from: ApplicationConfig.mail_from

  self.default_url_options = ApplicationConfig.default_url_options.symbolize_keys
end
