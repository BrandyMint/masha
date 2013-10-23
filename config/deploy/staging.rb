#Конфиг деплоя на staging
server 'mashtime.ru', :app, :web, :db, :primary => true
set :application, "staging.mashtime.ru"
set :port, 227
set(:current_branch) { `git branch`.match(/\* (\S+)\s/m)[1] || raise("Couldn't determine current branch") }
set :branch, defer { current_branch } unless exists?(:branch)
set :rails_env, "staging"
