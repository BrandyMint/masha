Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  unless Rails.env.test?
    provider :github, Settings::Omniauth.github.client_id, Settings::Omniauth.github.client_secret
  end
end
