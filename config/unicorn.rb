rails_env = ENV['RACK_ENV'] || 'production'
puts "Unicorn env: #{rails_env}"

if rails_env=='production'
  worker_processes 3
  APP_PATH = ENV['APP_PATH'] || '/home/wwwmasha/masha.brandymint.ru/'
  working_directory APP_PATH + "current"

  listen APP_PATH + "shared/pids/unicorn.sock"
  pid APP_PATH + "shared/pids/unicorn.pid"
  stderr_path APP_PATH + "shared/log/unicorn.stderr.log"
  stdout_path APP_PATH + "shared/log/unicorn.stdout.log"
else
  APP_PATH = ENV['APP_PATH'] || '/home/wwwmasha/masha.icfdev.ru/'
  stderr_path "log/unicorn.stderr.log"
  stdout_path "log/unicorn.stdout.log"
  pid "tmp/unicorn.pid"

  listen 4000, :tcp_nopush => true
end

# Helps ensure the correct unicorn binary is used when upgrading with USR2
# # See http://unicorn.bogomips.org/Sandbox.html
Unicorn::HttpServer::START_CTX[0] = "#{APP_PATH}current/bin/unicorn"

timeout 60
preload_app true

GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

# Rails breaks unicorn's logger formatting, reset it
# # http://rubyforge.org/pipermail/mongrel-unicorn/2010-October/000732.html
Unicorn::Configurator::DEFAULTS[:logger].formatter = Logger::Formatter.new

# Forcibly clean environment variables between bundlings
# http://www.mail-archive.com/mongrel-unicorn@rubyforge.org/msg00276.html
before_exec do |_|
  ENV["BUNDLE_GEMFILE"] = File.realpath(__FILE__+"/../../Gemfile")
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # Incremental kill-off
  #old_pid = "#{server.config[:pid]}.oldbin"
  #if old_pid != server.pid
  #  begin
  #    sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
  #    puts "Sending #{sig} signal to old unicorn master..."
  #    Process.kill(sig, File.read(old_pid).to_i)
  #  rescue Errno::ENOENT, Errno::ESRCH
  #  end
  #end

  # Throttle the master from forking too quickly (for incremental kill-off only)
  #sleep 1
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  child_pid = server.config[:pid].sub('.pid', ".#{worker.nr}.pid")
  system("echo #{Process.pid} > #{child_pid}")
end

