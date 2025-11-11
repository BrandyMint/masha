# frozen_string_literal: true

# Конфигурация fixtures для RSpec
RSpec.configure do |config|
  # Устанавливаем путь к fixtures
  config.fixture_paths = [Rails.root.join('spec/fixtures')]

  # Включаем transactional fixtures
  config.use_transactional_fixtures = true

  # Загружаем все fixtures для быстрого доступа
  config.global_fixtures = :all
end
