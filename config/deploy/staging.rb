set :stage, :staging
set :application, 'staging.mashtime.ru'
server 'staging.mashtime.ru', user: 'wwwmasha', roles: %w{web app db}
set :ssh_options, {
    forward_agent: true,
    port: 227
}
set :branch, ENV['BRANCH'] || proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :rails_env, :staging
fetch(:default_env).merge!(rails_env: :staging)
