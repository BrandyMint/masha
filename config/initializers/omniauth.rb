Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :github, Settings.omniauth.github.client_id, Settings.omniauth.github.client_secret
end
