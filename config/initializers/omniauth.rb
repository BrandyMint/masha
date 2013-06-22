Rails.application.config.middleware.use OmniAuth::Builder do
  #provider :developer unless Rails.env.production?
  provider :github, Settings::Omniauth.github.client_id, Settings::Omniauth.github.client_secret
end
