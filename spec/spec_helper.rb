# frozen_string_literal: true

require 'rubygems'

# Loading more in this block will cause your tests to run faster. However,
# if you change any configuration or code from libraries loaded here, you'll
# need to restart spork for it take effect.
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'telegram/bot/updates_controller/rspec_helpers'

# Configure shoulda-matchers after Rails is loaded
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Configure FactoryBot
require 'factory_bot_rails'

# ResqueSpec.disable_ext = true

RSpec.configure do |config|
  config.after { Telegram.bot.reset }

  # Suppress nil expectation warnings for Telegram testing
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.allow_message_expectations_on_nil = true
  end

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  if ENV['FORBID_FOCUSED_SPECS']
    config.before(:example, :focus) do
      raise ':focus should not be committed'
    end
  else
    config.filter_run_when_matching :focus
  end

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = Rails.root.join('spec/fixtures').to_s

  config.fail_fast = false

  config.include Sorcery::TestHelpers::Rails::Controller
  config.include ActiveSupport::Testing::TimeHelpers
  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:default, {
                             provider: 'github',
                             uid: '123456',
                             info: {
                               nickname: 'testuser',
                               email: 'test@example.com',
                               name: 'Test User'
                             }
                           })

  # Enable transactional fixtures для ускорения тестов
  config.use_transactional_fixtures = true

  # Загружаем все fixtures глобально для быстрого доступа
  config.global_fixtures = :all

  # Добавляем методы для доступа к fixtures
  config.include ActiveSupport::Testing::TimeHelpers

  # Добавляем методы FactoryBot
  config.include FactoryBot::Syntax::Methods

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Transactional fixtures handle cleanup for all tests
  # No DatabaseCleaner needed - using transactional fixtures only
end
