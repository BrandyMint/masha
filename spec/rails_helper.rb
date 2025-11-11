# frozen_string_literal: true

require './spec/spec_helper'

# Configure Rails Environment
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

require 'rspec/rails'

# Добавляем поддержку fixtures
require 'active_record/fixtures'

# Load fixtures automatically
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.global_fixtures = :all
end
