# План имплементации команды `/summary` v2.0

## Обзор
План для реализации расширенной команды `/summary` с поддержкой различных форматов периодов и справкой по умолчанию.

## Этапы реализации

### Этап 1: Подготовка - Создание парсера периодов

**Задача:**
- Создать класс `PeriodParser` для обработки всех форматов периодов
- Обеспечить валидацию входных данных
- Покрыть тестами все случаи парсинга

**Файлы:**
- `app/service/period_parser.rb` - новый файл
- `spec/services/period_parser_spec.rb` - тесты

**Реализация:**
```ruby
# app/service/period_parser.rb
class PeriodParser
  SUPPORTED_RELATIVE = %w[day week month last_month last_week last_day].freeze

  def self.parse(arg)
    return 'week' if arg.nil?

    case arg
    when *SUPPORTED_RELATIVE then arg
    when /^\d{4}-\d{2}$/ then { type: :month, date: Date.parse("#{arg}-01") }
    when /^\d{4}-\d{2}-\d{2}$/ then { type: :date, date: Date.parse(arg) }
    when /^\d{4}-\d{2}-\d{2}\.\.\.\d{4}-\d{2}-\d{2}$/ then parse_date_range(arg)
    when /^\d{4}-\d{2}\.\.\.\d{4}-\d{2}$/ then parse_month_range(arg)
    else raise ArgumentError, "Invalid period format"
    end
  rescue Date::Error => e
    raise ArgumentError, "Invalid date format: #{e.message}"
  end

  private

  def self.parse_date_range(range_str)
    start_date, end_date = range_str.split('..').map { |d| Date.parse(d) }
    validate_date_range(start_date, end_date)
    { type: :range, start_date: start_date, end_date: end_date }
  end

  def self.parse_month_range(range_str)
    start_month, end_month = range_str.split('..').map { |m| Date.parse("#{m}-01") }
    validate_date_range(start_month, end_month.end_of_month)
    { type: :month_range, start_date: start_month, end_date: end_month }
  end

  def self.validate_date_range(start_date, end_date)
    if start_date > end_date
      raise ArgumentError, "Start date cannot be after end date"
    end

    if (end_date - start_date).to_i > 365
      raise ArgumentError, "Period cannot exceed 365 days"
    end

    if start_date < 2.years.ago
      raise ArgumentError, "Data older than 2 years is not available"
    end
  end
end
```

### Этап 2: Модификация SummaryQuery

**Задача:**
- Обновить `SummaryQuery` для работы с новым парсером
- Добавить поддержку всех форматов периодов
- Обеспечить обратную совместимость

**Файлы:**
- `app/queries/summary_query.rb` - модификация существующего файла
- `spec/queries/summary_query_spec.rb` - обновление тестов

**Изменения:**
```ruby
# В SummaryQuery:
def self.for_user(user, period: nil)
  parsed_period = PeriodParser.parse(period)
  new(users: user.available_users,
      projects: user.available_projects,
      period: parsed_period)
end

private

def build_period(period)
  case period
  when 'week' then (Date.today - 6)..Date.today
  when 'month' then Date.today.beginning_of_month..Date.today
  when 'last_month' then (Date.today - 1.month).beginning_of_month..(Date.today - 1.month).end_of_month
  when 'last_week' then (Date.today - 1.week).beginning_of_week..(Date.today - 1.week).end_of_week
  when 'last_day' then Date.today - 1.day
  when Hash then build_period_from_hash(period)
  else raise ArgumentError, "Unsupported period"
  end
end

def build_period_from_hash(period_hash)
  case period_hash[:type]
  when :date then period_hash[:date]..period_hash[:date]
  when :month then period_hash[:date].beginning_of_month..period_hash[:date].end_of_month
  when :range then period_hash[:start_date]..period_hash[:end_date]
  when :month_range then period_hash[:start_date]..period_hash[:end_date].end_of_month
  end
end
```

### Этап 3: Обновление SummaryCommand

**Задача:**
- Добавить вывод справки по умолчанию
- Интегрировать новый парсер периодов
- Обработать ошибки с понятными сообщениями

**Файлы:**
- `app/controllers/telegram/commands/summary_command.rb` - модификация
- `spec/controllers/telegram/commands/summary_command_spec.rb` - обновление тестов

**Реализация:**
```ruby
# app/controllers/telegram/commands/summary_command.rb
class SummaryCommand < BaseCommand
  HELP_TEXT = <<~TEXT.freeze
    📊 *Команда /summary - Статистика по проектам и пользователям*

    *Форматы использования:*
    • `/summary day` - сегодня
    • `/summary week` - текущая неделя
    • `/summary month` - текущий месяц
    • `/summary last_month` - прошлый месяц
    • `/summary last_week` - прошлая неделя

    *Конкретные даты:*
    • `/summary 2024-11-05` - конкретная дата
    • `/summary 2024-11` - конкретный месяц
    • `/summary 2024-11-01..2024-11-05` - диапазон дат
    • `/summary 2024-10..2024-11` - диапазон месяцев

    *Примеры:*
    `/summary last_month` - статистика за прошлый месяц
    `/summary 2024-11-01..2024-11-07` - за первую неделю ноября
    `/summary 2024-10` - за октябрь 2024

    _Формат даты: ГГГГ-ММ-ДД, формат месяца: ГГГГ-ММ_
  TEXT

  def call(period = nil, *)
    if period.nil?
      respond_with :message, text: HELP_TEXT, parse_mode: :Markdown
      return
    end

    parsed_period = PeriodParser.parse(period)
    text = Reporter.new.projects_to_users_matrix(current_user, parsed_period)
    respond_with :message, text: code(text), parse_mode: :Markdown
  rescue ArgumentError => e
    respond_with :message, text: "❌ #{e.message}"
  rescue StandardError => e
    Rails.logger.error "SummaryCommand error: #{e.message}"
    respond_with :message, text: "❌ Произошла ошибка. Попробуйте еще раз."
  end
end
```

### Этап 4: Обновление Reporter

**Задача:**
- Модифицировать метод `projects_to_users_matrix` для работы с новыми форматами периодов
- Обеспечить корректный вывод заголовков для разных типов периодов

**Файлы:**
- `app/service/reporter.rb` - модификация метода `tableize_projects_to_users_matrix`

**Изменения:**
```ruby
# В app/service/reporter.rb, метод tableize_projects_to_users_matrix:
def tableize_projects_to_users_matrix(result)
  title = build_period_title(result[:period])
  # ... остальной код без изменений
end

private

def build_period_title(period)
  case period
  when 'week' then "#{Date.today - 6} - #{Date.today}"
  when 'month' then Date.today.strftime("%B %Y")
  when 'last_month' then (Date.today - 1.month).strftime("%B %Y")
  when 'last_week' then "Last week"
  when 'last_day' then (Date.today - 1.day).strftime("%Y-%m-%d")
  when Hash
    case period[:type]
    when :date then period[:date].strftime("%Y-%m-%d")
    when :month then period[:date].strftime("%B %Y")
    when :range then "#{period[:end_date]} - #{period[:start_date]}"
    when :month_range then "#{period[:end_date].strftime("%B %Y")} - #{period[:start_date].strftime("%B %Y")}"
    end
  else 'All days'
  end
end
```

### Этап 5: Тестирование

**Задача:**
- Написать комплексные тесты для всех компонентов
- Проверить все форматы периодов
- Протестировать обработку ошибок
- Проверить производительность

**Тестовые файлы:**
- `spec/services/period_parser_spec.rb` - новый
- `spec/queries/summary_query_spec.rb` - обновить
- `spec/controllers/telegram/commands/summary_command_spec.rb` - обновить
- `spec/services/reporter_spec.rb` - обновить

**Пример тестов:**
```ruby
# spec/services/period_parser_spec.rb
RSpec.describe PeriodParser do
  describe '.parse' do
    it 'parses relative periods' do
      expect(described_class.parse('week')).to eq('week')
      expect(described_class.parse('last_month')).to eq('last_month')
    end

    it 'parses date formats' do
      result = described_class.parse('2024-11-05')
      expect(result[:type]).to eq(:date)
      expect(result[:date]).to eq(Date.parse('2024-11-05'))
    end

    it 'parses date ranges' do
      result = described_class.parse('2024-11-01..2024-11-05')
      expect(result[:type]).to eq(:range)
      expect(result[:start_date]).to eq(Date.parse('2024-11-01'))
      expect(result[:end_date]).to eq(Date.parse('2024-11-05'))
    end

    it 'validates date ranges' do
      expect { described_class.parse('2024-11-05..2024-11-01') }
        .to raise_error(ArgumentError, 'Start date cannot be after end date')
    end
  end
end
```

## Сроки и приоритеты

**Критические изменения (высокий приоритет):**
1. PeriodParser - 2 дня
2. SummaryQuery модификация - 1 день
3. SummaryCommand обновление - 1 день

**Поддерживающие изменения (средний приоритет):**
4. Reporter обновление - 0.5 дня
5. Базовое тестирование - 2 дня

**Расширенное тестирование (низкий приоритет):**
6. Полное покрытие тестами - 2 дня
7. Performance тесты - 1 день

## Риски и митигация

**Риск 1:** Обратная совместимость
- **Митигация:** Сохранить существующее поведение для `/summary week`
- **Тестирование:** Проверить все существующие интеграции

**Риск 2:** Производительность
- **Митигация:** Оптимизировать запросы для больших диапазонов дат
- **Тестирование:** Load тесты для периодов > 30 дней

**Риск 3:** Сложность парсинга
- **Митигация:** Простые regex паттерны, исчерпывающая валидация
- **Тестирование:** Unit тесты с 100% покрытием

## Дополнительные улучшения (post-MVP)

1. **Кэширование результатов** для часто запрашиваемых периодов
2. **Предложенные команды** на основе истории использования
3. **Экспорт в CSV** для больших отчетов
4. **Графические представления** в веб-интерфейсе

## Критерии готовности

- [ ] Все форматы периодов работают корректно
- [ ] Help выводится при вызове без аргументов
- [ ] Ошибки обрабатываются с понятными сообщениями
- [ ] Все тесты проходят (минимум 90% покрытие)
- [ ] Производительность не ухудшена (>2 секунды для любой команды)
- [ ] Документация обновлена
- [ ] Обратная совместимость сохранена