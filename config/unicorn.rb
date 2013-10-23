rails_env = ENV['RACK_ENV'] || 'production'

APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

worker_processes 3
working_directory APP_ROOT
listen APP_ROOT + "/tmp/sockets/unicorn.sock"
pid  APP_ROOT + "/tmp/pids/unicorn.pid"
stderr_path APP_ROOT + "/log/unicorn.stderr.log"
stdout_path APP_ROOT + "/log/unicorn.stdout.log"

if rails_env=='production'
    worker_processes 10
end

# Helps ensure the correct unicorn binary is used when upgrading with USR2
# # See http://unicorn.bogomips.org/Sandbox.html
Unicorn::HttpServer::START_CTX[0] = APP_ROOT + "/bin/unicorn"

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
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  child_pid = server.config[:pid].sub('.pid', ".#{worker.nr}.pid")
  system("echo #{Process.pid} > #{child_pid}")
end
