source 'http://rubygems.org'

gem 'puma'

gem 'rails', '~> 5.2'

# Use postgresql as the database for ActiveRecord
gem 'pg'
# gem 'squash_migrations'

gem 'rake'

gem 'settingslogic'

gem 'rails_autolink'
# gem 'cache_digests'

gem 'auto_logger'
gem 'russian'

gem 'breadcrumbs_on_rails'

# Управление версиями проекта
gem 'semver2'

# Авторизация и аутентификация
gem 'omniauth'
gem 'omniauth-github'
gem 'authority'
gem 'sorcery'
# gem 'rolify'
gem 'simple_enum'

gem 'socksify'
gem 'telegram-bot', github: 'telegram-bot-rb/telegram-bot'
# gem 'telegram-bot-types'

# Модели, value object и form objects
# gem 'phony_rails', :git => 'git://github.com/joost/phony_rails.git'
gem 'active_attr'
gem 'validates'
gem 'validates_timeliness', '~> 3.0'
gem 'hashie'

gem 'friendly_id', '~> 5.0.0'
# берется последняя версия для совместимости с rails 4
# gem 'state_machine', :git => 'git://github.com/pluginaweek/state_machine.git'
# gem 'simple_enum'
# gem 'enumerize'

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Авторизация
# gem 'switch_user'

# Почта
gem 'recipient_interceptor'

gem 'mini_magick'
gem 'mini_racer'
gem 'carrierwave'

# Контроллеры
# gem 'has_scope'
gem 'responders', github: 'plataformatec/responders'
gem 'inherited_resources', github: 'josevalim/inherited_resources'

# "~> 1.4.0"

# Используется для сидирования обьектов
# gem 'forgery'
# gem 'ffaker'

# Вьюхи и презентеры
gem 'active_link_to'

gem 'draper'
gem 'arbre'

gem 'rubyzip', '>= 1.2.1'
gem 'axlsx', git: 'https://github.com/randym/axlsx.git', ref: 'c8ac844'
gem 'axlsx_rails'
# gem 'cells'
# gem 'breadcrumbs_on_rails'
# gem 'tabulous'
# gem 'authbuttons-rails'

gem 'simple-navigation', '~> 3.13.0' # git: 'git://github.com/andi/simple-navigation.git'
gem 'simple-navigation-bootstrap'

gem 'simple_form', github: 'plataformatec/simple_form'

# gem 'nested_form'
# gem 'cocoon'

gem 'kaminari'
gem 'kaminari-bootstrap'

# Use jquery as the JavaScript library
gem 'jquery-rails' # , '2.3.0'
gem 'turbolinks', '~> 5'
# gem 'jquery-turbolinks'

# gem 'nilify_blanks', :git => 'git://github.com/rubiety/nilify_blanks.git'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
gem 'haml-rails'

gem 'bootstrap-sass'
gem 'sass-rails'
gem 'compass-rails'

# active admin
gem 'activeadmin', github: 'gregbell/active_admin'

gem 'sendgrid-actionmailer'

# Очередь
# gem 'redis-namespace'
# gem 'resque'
# gem 'resque-pool'
# gem 'resque-status'

# gem 'ruby-progressbar'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 1.0.1'

# gem 'honeybadger', github: 'honeybadger-io/honeybadger-ruby' # , :require => 'honeybadger/rails'

gem 'github_api'

# Use edge version of sprockets-rails
gem 'sprockets-rails'
gem 'sprockets'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'
gem 'role-rails'
gem 'non-stupid-digest-assets'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Хорошая альтернатива jquery-ui-rails
gem 'jquery-ui-sass-rails'
# gem 'jquery_datepicker'

# gem 'select2-rails'
gem 'gritter', '1.1.0'

gem 'sidekiq'
gem 'redis'
gem 'hiredis'

gem 'terminal-table'
gem 'russian'

# Used for telegram sessions
gem 'redis-rails'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development, :test do
  gem 'rspec-rails' # , ">= 2.11.0"
  gem 'rb-inotify', '~> 0.9', require: false
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
end

group :development do
  gem 'bond'

  gem 'spring-commands-rspec'

  gem 'hpricot', '>= 0.8.6'
  gem 'ruby_parser', '>= 2.3.1'

  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rb-fsevent', '~> 0.9.1', require: false

  gem 'letter_opener_web'
end

group :test do
  gem 'factory_bot'
  gem 'factory_bot_rails', github: 'thoughtbot/factory_bot_rails'

  gem 'rails-controller-testing'

  gem 'rspec-prof'
  # Start Pry in the context of a failed test
  # gem 'plymouth'
  gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'resque_spec'
  gem 'email_spec', '>= 1.2.1'
  gem 'guard'
  # gem 'debugger' unless `whoami`=~/jenkins/
  gem 'guard-rspec'
  #gem 'guard-rails'
  # gem 'guard-bundler'
  #gem 'guard-cucumber'
  gem 'guard-ctags-bundler'

  gem 'database_cleaner'

  gem 'launchy', '>= 2.1.2'
  gem 'turn', require: false
  # gem "test_active_admin", :git => "git://github.com/BrandyMint/test_active_admin.git"
end

group :deploy do
  gem 'capistrano', '~> 3.2', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-nvm', require: false
  gem 'capistrano-bundler', github: 'capistrano/bundler', require: false
  gem 'capistrano-yarn', require: false
  gem 'capistrano-shell', require: false
  gem 'capistrano-db-tasks', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma', require: false
  gem 'capistrano-git-with-submodules', '~> 2.0', github: 'ekho/capistrano-git-with-submodules'
end

gem 'rubocop', require: false

gem "bugsnag", "~> 6.11"
