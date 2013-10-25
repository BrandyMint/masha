set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'
#
#Приложение
set :application, "mashtime.ru"

#Репозиторий
set :scm, :git
set :repository,  'git://github.com/BrandyMint/masha.git'
set :deploy_via, :remote_cache
set :scm_verbose, true
ssh_options[:forward_agent] = true

#Учетные данные на сервере
set :user,      'wwwmasha'
set :deploy_to,  defer { "/home/#{user}/#{application}" }
set :use_sudo,   false

#Все остальное
set :keep_releases, 3
set :shared_children, %w(log)

set :rbenv_ruby_version, "2.0.0-p247"
set :bundle_flags, "--deployment --quiet --binstubs"

before 'deploy:restart', 'deploy:migrate'
after 'deploy:update_code', 'deploy:bower install'
after 'deploy', "deploy:cleanup"

#RVM, Bundler
load 'deploy/assets'
require 'airbrake/capistrano'
require "bundler/capistrano"
require "capistrano-rbenv"
require 'holepicker/capistrano'
require "recipes0/database_yml"
require "recipes0/db/pg"
require "recipes0/init_d/unicorn"
require "recipes0/nginx"

after "deploy:db:symlink", "deploy:config_symlink"

namespace :deploy do
  task :config_symlink do
    run [
        "ln -nfs #{shared_path}/public/system #{release_path}/public/system",
        "ln -nfs #{shared_path}/public/uploads #{release_path}/public/uploads",
        "mkdir -p #{release_path}/tmp",
        "ln -nfs #{shared_path}/tmp/pids #{release_path}/tmp/pids",
        "ln -nfs #{shared_path}/tmp/cache #{release_path}/tmp/cache",
        "ln -nfs #{shared_path}/tmp/sockets #{release_path}/tmp/sockets",
        "ln -nfs #{shared_path}/config/omniauth.yml #{release_path}/config/omniauth.yml"
    ].join(" && ")
  end

  desc "Installing bower components"
  task :bowerinstall do
    run "cd #{latest_release} && bower install"
  end
end
