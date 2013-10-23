#Конфиг деплоя на staging
server 'mashtime.ru', :app, :web, :db, :primary => true
set :port, 227
set :branch, "master" unless exists?(:branch)
set :rails_env, "production"
