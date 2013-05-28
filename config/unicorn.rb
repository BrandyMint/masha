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

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 60
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true
GC::Profiler.enable

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  old_pid = Rails.root + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      puts "Old master alerady dead"
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  child_pid = server.config[:pid].sub('.pid', ".#{worker.nr}.pid")
  system("echo #{Process.pid} > #{child_pid}")

end

