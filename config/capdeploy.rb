#
#Приложение
set :application, "masha.brandymint.ru"

#Репозиторий
set :scm, :git
set :repository,  'git://github.com/BrandyMint/masha.git'
set :deploy_via, :remote_cache
set :scm_verbose, true
ssh_options[:forward_agent] = true

server 'icfdev.ru', :app, :web, :db, :primary => true
set :branch, "master" unless exists?(:branch)
set :rails_env, "production"

#Учетные данные на сервере
set :user,      'wwwmasha'
set :deploy_to,  defer { "/home/#{user}/#{application}" }
set :use_sudo,   false

#Все остальное
set :keep_releases, 3
set :shared_children, fetch(:shared_children) + %w(public/uploads)

set :rbenv_ruby_version, "2.0.0-p195"
set :bundle_flags, "--deployment --quiet --binstubs"

before 'deploy:restart', 'deploy:migrate'
after 'deploy:restart', "deploy:cleanup"

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

