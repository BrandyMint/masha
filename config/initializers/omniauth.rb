Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.development?
    provider :developer
    provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], scope: 'user'

  elsif Rails.env.production?
    github = Rails.application.credentials.github
    if github.present?
      provider :github, github[:client_id], github[:client_secret], scope: 'user'
    else
      puts
      puts 'Please set up github setting in ./config/secrets.yml'
    end
  end
end

OmniAuth.config.logger = Rails.logger

OmniAuth.config.allowed_request_methods = [:post, :get]
