# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  provider :github, ApplicationConfig.github_client_id, ApplicationConfig.github_client_secret, scope: 'user'
end

OmniAuth.config.logger = Rails.logger

OmniAuth.config.allowed_request_methods = %i[post get]
