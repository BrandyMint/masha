lock '3.11.0'
set :application, 'masha.brandymint.ru'
set :repo_url, 'https://github.com/BrandyMint/masha.git'

set :user, 'wwwbrandymint'

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :log_level, :info

set :linked_files, %w(config/database.yml config/master.key)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads)

set :nvm_type, :user # or :system, depends on your nvm setup
set :nvm_node, File.read('.nvmrc').strip
set :nvm_map_bins, %w[node yarn]

# if you want to remove the local dump file after loading
set :db_local_clean, true
# if you want to remove the dump file from the server after downloading
set :db_remote_clean, false

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
append :rbenv_map_bins, 'puma', 'pumactl'

set :nginx_server_name,  -> { "#{fetch(:application)}" }

set :bundle_without, %w(development test deploy).join(' ')
set :bundle_jobs, 10

set :puma_threads, [0, 4]
