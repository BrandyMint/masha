# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], scope: 'user'
end

OmniAuth.config.logger = Rails.logger

OmniAuth.config.allowed_request_methods = %i[post get]
