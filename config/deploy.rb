lock '3.11.0'
set :application, 'masha.brandymint.ru'
set :repo_url, 'https://github.com/BrandyMint/masha.git'

set :user, 'wwwbrandymint'

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :log_level, :info

set :linked_files, %w(config/database.yml config/master.key)
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/uploads)

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

set :bundle_without, %w(development test deploy).join(' ')
set :bundle_jobs, 10

set :puma_threads, [0, 4]

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      execute "/etc/init.d/unicorn-#{fetch(:application)} upgrade"
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  before :compile_assets, 'bower:install'
  after :publishing, :restart
  after :finishing, 'deploy:cleanup'
end
