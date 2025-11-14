# frozen_string_literal: true

namespace :analyze do
  desc 'Анализ использования FactoryBot в тестах'
  task factories: :environment do
    puts '🔍 Анализ использования FactoryBot в тестах'
    puts '=' * 50

    # Анализ использования factory методов
    analyze_factory_usage

    # Анализ самых популярных factories
    analyze_popular_factories

    # Анализ трейтов
    analyze_traits_usage

    # Анализ ассоциаций
    analyze_associations

    # Анализ по типам тестов
    analyze_by_test_type

    # Рекомендации для fixtures
    generate_fixture_recommendations
  end

  private

  def analyze_factory_usage
    puts "\n📊 Статистика использования factory методов:"

    create_count = `grep -r "create(" spec/ | wc -l`.to_i
    build_count = `grep -r "build(" spec/ | wc -l`.to_i
    build_stubbed_count = `grep -r "build_stubbed(" spec/ | wc -l`.to_i

    puts "  • create(): #{create_count} вызовов"
    puts "  • build(): #{build_count} вызовов"
    puts "  • build_stubbed(): #{build_stubbed_count} вызовов"
    puts "  • Всего: #{create_count + build_count + build_stubbed_count} вызовов"
  end

  def analyze_popular_factories
    puts "\n🏆 Самые популярные factories:"

    factory_counts = Hash.new(0)

    Dir.glob('spec/**/*_spec.rb').each do |file|
      content = File.read(file)
      # Ищем паттерны типа create(:user), create(:project, :with_owner)
      content.scan(/create\(:([a-z_]+)/).each do |match|
        factory_counts[match[0]] += 1
      end
    end

    factory_counts.sort_by { |_, count| -count }.first(10).each_with_index do |(factory, count), index|
      puts "  #{index + 1}. #{factory}: #{count} использований"
    end
  end

  def analyze_traits_usage
    puts "\n🎭 Использование трейтов:"

    trait_usage = Hash.new(0)

    Dir.glob('spec/**/*_spec.rb').each do |file|
      content = File.read(file)
      # Ищем паттерны типа create(:project, :with_owner)
      content.scan(/create\(:[a-z_]+,\s*:([a-z_]+)/).each do |match|
        trait_usage[match[0]] += 1
      end
    end

    if trait_usage.any?
      trait_usage.sort_by { |_, count| -count }.each do |trait, count|
        puts "  • #{trait}: #{count} использований"
      end
    else
      puts '  • Трейты не найдены'
    end
  end

  def analyze_associations
    puts "\n🔗 Анализ ассоциаций в factory файлах:"

    Dir.glob('spec/factories/*.rb').each do |file|
      factory_name = File.basename(file, '.rb')
      content = File.read(file)

      associations = []
      content.scan(/association\s+(:[a-z_]+)/).each do |match|
        associations << match[0]
      end

      puts "  #{factory_name}: #{associations.join(', ')}" if associations.any?
    end
  end

  def analyze_by_test_type
    puts "\n📋 Распределение по типам тестов:"

    test_types = {
      'Models' => 'spec/models',
      'Controllers' => 'spec/controllers',
      'Services' => 'spec/services',
      'Jobs' => 'spec/jobs',
      'Decorators' => 'spec/decorators',
      'Form Objects' => 'spec/form_objects',
      'Queries' => 'spec/queries',
      'Authorizers' => 'spec/authorizers'
    }

    test_types.each do |type, path|
      next unless Dir.exist?(path)

      files = Dir.glob("#{path}/*_spec.rb")
      total_creates = 0

      files.each do |file|
        content = File.read(file)
        total_creates += content.scan('create(').length
      end

      puts "  #{type}: #{files.length} файлов, #{total_creates} create()"
    end
  end

  def generate_fixture_recommendations
    puts "\n💡 Рекомендации для fixtures:"

    # Анализ самых частых паттернов
    common_patterns = analyze_common_patterns

    puts "\n🎯 Кандидаты для fixtures (высокочастотное использование):"
    common_patterns[:fixture_candidates].each do |pattern|
      puts "  • #{pattern[:name]} - #{pattern[:count]} использований"
    end

    puts "\n🏗️ Сложные сценарии (оставить в factories):"
    common_patterns[:complex_scenarios].each do |pattern|
      puts "  • #{pattern[:name]} - #{pattern[:reason]}"
    end

    puts "\n📝 Предлагаемая структура fixtures:"
    puts '  users.yml - базовые пользователи (admin, regular, with_telegram)'
    puts '  projects.yml - типовые проекты (work, personal, inactive)'
    puts '  memberships.yml - связи пользователей и проектов с ролями'
    puts '  telegram_users.yml - telegram аккаунты'
    puts '  time_shifts.yml - базовые временные записи'

    puts "\n⚡ Ожидаемое ускорение:"
    puts '  • Прямые тесты: 5-10x быстрее'
    puts '  • Telegram webhook: 3-5x быстрее'
    puts '  • Интеграционные тесты: 2-3x быстрее'
  end

  def analyze_common_patterns
    # Анализ частых паттернов для рекомендаций
    fixture_candidates = []

    # Самые популярные factory на основе предыдущего анализа
    popular_factories = {
      'user' => 0,
      'project' => 0,
      'time_shift' => 0,
      'membership' => 0,
      'telegram_user' => 0
    }

    Dir.glob('spec/**/*_spec.rb').each do |file|
      content = File.read(file)

      popular_factories.each_key do |factory|
        count = content.scan(/create\(:#{factory}/).length
        popular_factories[factory] += count
      end
    end

    # Определяем кандидатов для fixtures
    popular_factories.select { |_, count| count > 10 }.each do |factory, count|
      fixture_candidates << {
        name: factory,
        count: count
      }
    end

    # Сложные сценарии которые лучше оставить в factories
    complex_scenarios = [
      { name: 'time_shifts с кастомными датами', reason: 'динамические даты и периоды' },
      { name: 'complex memberships с ролями', reason: 'различные роли и права доступа' },
      { name: 'telegram webhook сценарии', reason: 'специфичные контексты и callback данные' },
      { name: 'reporting данные', reason: 'большие объемы и агрегации' }
    ]

    {
      fixture_candidates: fixture_candidates,
      complex_scenarios: complex_scenarios
    }
  end
end
