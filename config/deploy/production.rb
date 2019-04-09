set :stage, :production
server 'masha.brandymint.ru', user: fetch(:user), roles: %w(web app db)

set :branch, ENV['BRANCH'] || 'master'
set :rails_env, :production
fetch(:default_env).merge!(rails_env: :production)
