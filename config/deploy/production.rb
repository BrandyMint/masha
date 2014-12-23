set :stage, :production
server 'mashtime.ru', user: 'wwwmasha', roles: %w(web app db)
set :ssh_options,
    forward_agent: true,
    port: 227

set :branch, ENV['BRANCH'] || 'master'
set :rails_env, :production
fetch(:default_env).merge!(rails_env: :production)
