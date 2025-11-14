# План имплементации FIP-001: Унификация команд отчетов

**Связанная спецификация**: [FIP-001-report-unification.md](./FIP-001-report-unification.md)
**Общая оценка**: 5.2 рабочих дней
**Дата начала**: 2025-11-14
**Дата завершения**: TBD

---

## 📊 ПРОГРЕСС ИМПЛЕМЕНТАЦИИ

**Последнее обновление**: 2025-11-14
**Статус**: В процессе - Этап 2 завершен (2/6)

### ✅ Завершенные этапы

#### Этап 1: Подготовка и анализ (0.5 дня) ✅
**Дата завершения**: 2025-11-14

**Выполненные задачи**:
- ✅ 1.1 Анализ существующих команд (`/day`, `/summary`, `/hours`, `/report`)
- ✅ 1.2 Анализ модели TimeShift и оптимизация запросов
- ✅ 1.3 Подготовка тестовых данных (fixtures)

**Ключевые находки**:
- Все команды используют Terminal::Table для форматирования
- PeriodParser уже реализован в `app/services/period_parser.rb`
- TimeShift использует scopes: `ordered`, `this_day`
- Fixtures используют ERB для динамических дат
- База данных имеет составной индекс `[date, project_id, user_id]`

#### Этап 2: ReportBuilder - Ядро системы (2 дня) ✅
**Дата завершения**: 2025-11-14

**Созданные файлы**:
- `app/services/report_builder.rb` (141 строка)
- `spec/services/report_builder_spec.rb` (560+ строк, 56 тестов)

**Выполненные задачи**:
- ✅ 2.1 Создание базовой структуры ReportBuilder (12 тестов)
  - Инициализация с параметрами (user, period, filters, options)
  - Метод `build` возвращающий структурированный отчет
  - Базовые тесты на структуру данных

- ✅ 2.2 Парсинг периодов (23 теста)
  - Именованные периоды: `:today`, `:yesterday`, `:week`, `:month`, `:quarter`
  - Формат строковых периодов: `'today'`, `'week'`, etc.
  - Формат одной даты: `'YYYY-MM-DD'`
  - Формат диапазона: `'YYYY-MM-DD:YYYY-MM-DD'`
  - Edge cases: невалидные даты, fallback на today
  - Граничные случаи: конец месяца, високосный год

- ✅ 2.3 Фильтрация по проектам (8 тестов)
  - Одиночный проект: `filters: { project: 'slug' }`
  - Множественные проекты: `filters: { projects: 'slug1,slug2' }`
  - Обработка пробелов в списке проектов
  - Обработка несуществующих проектов (scope.none)
  - Eager loading с `.includes(:project)`

- ✅ 2.4 Группировка данных (13 тестов)
  - `grouped_by_project`: группировка по slug проекта
  - `grouped_by_day`: группировка по дате
  - Подсчет hours и count для каждой группы
  - Валидация сумм и корректности

**Структура ReportBuilder**:
```ruby
ReportBuilder.new(
  user: user,
  period: :today | :week | :month | :quarter | 'YYYY-MM-DD' | 'YYYY-MM-DD:YYYY-MM-DD',
  filters: {
    project: 'slug',           # одиночный проект
    projects: 'slug1,slug2'    # множественные проекты
  },
  options: {}
)

# Возвращает:
{
  period: { from: Date, to: Date },
  total_hours: Float,
  entries: [{ date: Date, project: Project, hours: Float, description: String }],
  grouped_by_project: { 'slug' => { hours: Float, count: Integer } },
  grouped_by_day: { Date => { hours: Float, count: Integer } }
}
```

**Результаты тестирования**:
- Всего тестов: 56
- Прошло: 56 ✅
- Провалилось: 0
- Покрытие: полное покрытие основной функциональности

### 🔄 Текущая работа

**Следующий этап**: Этап 3 - ReportFormatter (1 день)

**Что нужно сделать**:
1. Создать `app/services/report_formatter.rb`
2. Создать `spec/services/report_formatter_spec.rb`
3. Реализовать форматы:
   - Summary формат (краткая таблица)
   - Detailed формат (с описаниями)
4. Интеграция с Terminal::Table
5. Локализация через I18n

### 📋 Оставшиеся этапы

- ⏳ Этап 3: ReportFormatter - Форматирование вывода (1 день)
- ⏳ Этап 4: ReportCommand - Интерфейс команды (1 день)
- ⏳ Этап 5: Миграция старых команд (0.5 дня)
- ⏳ Этап 6: Документация и релиз (0.5 дня)

### 🎯 Следующие шаги для продолжения

1. **Начать Этап 3.1**: Создать базовую структуру ReportFormatter
2. **Изучить существующие форматтеры**: Посмотреть Reporter и другие сервисы
3. **Определить интерфейс**: `ReportFormatter.new(report_data, format: :summary|:detailed)`
4. **Написать тесты**: Для summary и detailed форматов
5. **Реализовать**: Форматирование с Terminal::Table

### 📝 Технические заметки

**Важные решения**:
- Использовать `scope.none` для пустых результатов при несуществующих фильтрах
- Eager loading обязателен: `.includes(:project)` в base_scope
- Fallback на `:today` для всех невалидных периодов
- Группировка использует `entries` (не прямые запросы) для консистентности

**Проблемы и решения**:
1. **Проблема**: Nested `travel_to` блоки в RSpec
   - **Решение**: Вынести тесты из вложенного `around` блока

2. **Проблема**: Фильтры не применялись для несуществующих проектов
   - **Решение**: Использовать `scope.none` вместо игнорирования фильтра

**Паттерны для следующих этапов**:
- ReportFormatter должен принимать output от ReportBuilder.build
- Использовать Terminal::Table для форматирования
- Все тексты через I18n (не хардкодить)
- TDD подход: сначала тесты, потом реализация

---

## Общая стратегия

1. **Снизу вверх**: Сначала строим фундамент (ReportBuilder), затем интерфейсы (ReportCommand, ReportFormatter)
2. **TDD подход**: Тесты пишутся до/вместе с кодом
3. **Итеративная интеграция**: Каждый этап заканчивается рабочей версией
4. **Постепенная миграция**: Старые команды превращаются в алиасы, а не удаляются

## Этап 1: Подготовка и анализ (0.5 дня) ✅

**Статус**: Завершен 2025-11-14

### Задачи

#### 1.1 Анализ существующих команд ✅
- [x] Изучить текущую реализацию `/day` command
- [x] Изучить текущую реализацию `/summary` command
- [x] Изучить текущую реализацию `/hours` command
- [x] Изучить текущую реализацию `/report` command
- [x] Выделить общую логику и паттерны

**Файлы**:
- `app/commands/day_command.rb`
- `app/commands/summary_command.rb`
- `app/commands/hours_command.rb`
- `app/commands/report_command.rb` (если существует)

#### 1.2 Анализ запросов к TimeShift ✅
- [x] Изучить модель TimeShift
- [x] Изучить существующие scopes и методы
- [x] Определить оптимальные запросы для разных типов отчетов

**Файлы**:
- `app/models/time_shift.rb`
- `db/schema.rb`

#### 1.3 Подготовка тестовых данных ✅
- [x] Создать/обновить fixtures для тестирования
- [x] Подготовить тестовые сценарии

**Файлы**:
- `spec/fixtures/time_shifts.yml`

**Критерий завершения**: Полное понимание текущей архитектуры и готовые тестовые данные ✅

---

## Этап 2: ReportBuilder - Ядро системы (2 дня) ✅

**Статус**: Завершен 2025-11-14
**Результат**: 56 тестов, все проходят ✅

### 2.1 Создание базовой структуры (0.5 дня) ✅

#### Задачи
- [x] Создать класс `ReportBuilder` с базовой структурой
- [x] Определить публичный API класса
- [x] Создать базовые тесты (12 тестов)

**Файлы для создания**:
```ruby
# app/services/report_builder.rb
class ReportBuilder
  attr_reader :user, :period, :filters, :options

  def initialize(user:, period: :today, filters: {}, options: {})
    @user = user
    @period = period
    @filters = filters
    @options = options
  end

  def build
    {
      period: parse_period,
      total_hours: calculate_total_hours,
      entries: fetch_entries,
      grouped_by_project: group_by_project,
      grouped_by_day: group_by_day
    }
  end

  private

  def parse_period
    # Парсинг периода в { from: Date, to: Date }
  end

  def fetch_entries
    # Основной запрос к TimeShift
  end

  def calculate_total_hours
    # Подсчет общего времени
  end

  def group_by_project
    # Группировка по проектам
  end

  def group_by_day
    # Группировка по дням
  end
end
```

**Тесты**:
```ruby
# spec/services/report_builder_spec.rb
RSpec.describe ReportBuilder do
  let(:user) { users(:user_with_telegram) }

  describe '#initialize' do
    it 'accepts required parameters'
    it 'sets default values'
  end

  describe '#build' do
    it 'returns report structure'
  end
end
```

### 2.2 Парсинг периодов (0.5 дня) ✅

#### Задачи
- [x] Реализовать парсинг именованных периодов (today, week, month, quarter)
- [x] Реализовать парсинг дат (YYYY-MM-DD)
- [x] Реализовать парсинг диапазонов (YYYY-MM-DD:YYYY-MM-DD)
- [x] Добавить валидацию
- [x] Покрыть тестами все варианты (23 теста)

**Примеры тестов**:
```ruby
describe '#parse_period' do
  context 'named periods' do
    it 'parses :today' do
      builder = ReportBuilder.new(user: user, period: :today)
      expect(builder.send(:parse_period)).to eq(
        from: Date.current,
        to: Date.current
      )
    end

    it 'parses :week' do
      builder = ReportBuilder.new(user: user, period: :week)
      period = builder.send(:parse_period)
      expect(period[:from]).to eq(Date.current.beginning_of_week)
      expect(period[:to]).to eq(Date.current.end_of_week)
    end

    it 'parses :month'
    it 'parses :quarter'
    it 'parses :yesterday'
  end

  context 'date strings' do
    it 'parses single date' do
      builder = ReportBuilder.new(user: user, period: '2024-01-15')
      expect(builder.send(:parse_period)).to eq(
        from: Date.parse('2024-01-15'),
        to: Date.parse('2024-01-15')
      )
    end

    it 'parses date range' do
      builder = ReportBuilder.new(user: user, period: '2024-01-01:2024-01-31')
      expect(builder.send(:parse_period)).to eq(
        from: Date.parse('2024-01-01'),
        to: Date.parse('2024-01-31')
      )
    end

    it 'raises error for invalid date'
    it 'raises error for invalid range'
  end
end
```

### 2.3 Фильтрация и запросы (0.5 дня)

#### Задачи
- [ ] Реализовать фильтрацию по проекту
- [ ] Реализовать фильтрацию по нескольким проектам
- [ ] Оптимизировать запросы (eager loading)
- [ ] Покрыть тестами

**Примеры тестов**:
```ruby
describe '#fetch_entries' do
  context 'without filters' do
    it 'returns all entries for period'
  end

  context 'with project filter' do
    it 'returns only entries for specified project'
  end

  context 'with multiple projects filter' do
    it 'returns entries for all specified projects'
  end

  context 'with date range' do
    it 'returns entries within date range'
  end
end
```

### 2.4 Группировка данных (0.5 дня)

#### Задачи
- [ ] Реализовать группировку по проектам
- [ ] Реализовать группировку по дням
- [ ] Реализовать подсчет итогов
- [ ] Покрыть тестами

**Примеры тестов**:
```ruby
describe '#group_by_project' do
  it 'groups entries by project'
  it 'calculates total hours per project'
  it 'counts entries per project'
end

describe '#group_by_day' do
  it 'groups entries by day'
  it 'calculates total hours per day'
  it 'counts entries per day'
end

describe '#calculate_total_hours' do
  it 'sums all hours in period'
end
```

**Критерий завершения**: ReportBuilder полностью функционален и покрыт тестами

---

## Этап 3: ReportFormatter - Форматирование вывода (1 день)

### 3.1 Создание базовой структуры (0.3 дня)

#### Задачи
- [ ] Создать класс `ReportFormatter`
- [ ] Определить публичный API
- [ ] Создать базовые тесты

**Файлы для создания**:
```ruby
# app/services/report_formatter.rb
class ReportFormatter
  attr_reader :report_data, :format_options

  def initialize(report_data, format_options = {})
    @report_data = report_data
    @format_options = format_options
  end

  def format
    return format_detailed if detailed?
    format_summary
  end

  private

  def detailed?
    format_options[:detailed] == true
  end

  def format_summary
    # Краткий формат
  end

  def format_detailed
    # Детальный формат
  end

  def format_by_day
    # Группировка по дням
  end

  def format_by_project
    # Группировка по проектам
  end
end
```

### 3.2 Summary формат (0.3 дня)

#### Задачи
- [ ] Реализовать краткий формат отчета
- [ ] Добавить emoji и форматирование
- [ ] Добавить итоговую статистику
- [ ] Покрыть тестами

**Пример вывода**:
```
📊 Отчет за неделю (13.01 - 19.01)

💼 Проекты:
• Work Project: 32.5ч (13 записей)
• Personal: 8.0ч (5 записей)

⏱ Всего: 40.5 часов
```

**Тесты**:
```ruby
describe '#format_summary' do
  it 'includes period header'
  it 'lists projects with hours'
  it 'shows total hours'
  it 'uses correct emoji'
end
```

### 3.3 Detailed формат (0.4 дня)

#### Задачи
- [ ] Реализовать детальный формат с описаниями
- [ ] Добавить группировку по дням/проектам
- [ ] Добавить форматирование дат
- [ ] Покрыть тестами

**Пример вывода**:
```
📊 Детальный отчет за неделю (13.01 - 19.01)

📅 Понедельник, 13 января:
  Work Project (8.0ч):
    • 6.0ч - Разработка новой функции
    • 2.0ч - Code review

📅 Вторник, 14 января:
  Work Project (7.5ч):
    • 5.0ч - Фикс багов
    • 2.5ч - Тестирование

⏱ Всего за неделю: 40.5 часов
```

**Тесты**:
```ruby
describe '#format_detailed' do
  it 'includes all entries with descriptions'
  it 'groups by day when requested'
  it 'groups by project when requested'
  it 'formats dates correctly'
end
```

**Критерий завершения**: ReportFormatter работает для всех типов отчетов

---

## Этап 4: ReportCommand - Интерфейс команды (1 день)

### 4.1 Парсинг параметров (0.4 дня)

#### Задачи
- [ ] Создать класс `ReportCommand`
- [ ] Реализовать парсинг аргументов команды
- [ ] Добавить валидацию параметров
- [ ] Покрыть тестами

**Файлы для создания**:
```ruby
# app/commands/report_command.rb
class ReportCommand < BaseCommand
  def call!(*args)
    params = parse_params(args)

    report_data = ReportBuilder.new(
      user: current_user,
      period: params[:period],
      filters: params[:filters],
      options: params[:options]
    ).build

    formatted_report = ReportFormatter.new(
      report_data,
      params[:options]
    ).format

    respond_with :message, text: formatted_report
  end

  private

  def parse_params(args)
    # Парсинг аргументов
  end
end
```

**Примеры парсинга**:
```ruby
# /report → { period: :today, filters: {}, options: {} }
# /report week → { period: :week, filters: {}, options: {} }
# /report week project:work → { period: :week, filters: { project: 'work' }, options: {} }
# /report month detailed → { period: :month, filters: {}, options: { detailed: true } }
```

**Тесты**:
```ruby
# spec/commands/report_command_spec.rb
RSpec.describe ReportCommand, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'
  include_context 'authenticated user'

  describe 'parameter parsing' do
    it 'parses no arguments as today'
    it 'parses period argument'
    it 'parses project filter'
    it 'parses detailed option'
    it 'parses combined parameters'
  end

  describe 'error handling' do
    it 'handles invalid period'
    it 'handles invalid project slug'
    it 'handles invalid date format'
  end
end
```

### 4.2 Интеграция компонентов (0.3 дня)

#### Задачи
- [ ] Интегрировать ReportBuilder и ReportFormatter
- [ ] Добавить обработку ошибок
- [ ] Добавить логирование
- [ ] Покрыть интеграционными тестами

**Интеграционные тесты**:
```ruby
describe 'full workflow' do
  context 'basic reports' do
    it 'generates today report' do
      response = dispatch_command :report
      expect(response).to include('Отчет за')
    end

    it 'generates week report' do
      response = dispatch_command :report, 'week'
      expect(response).to include('неделю')
    end

    it 'generates month report' do
      response = dispatch_command :report, 'month'
      expect(response).to include('месяц')
    end
  end

  context 'with filters' do
    it 'generates project report' do
      response = dispatch_command :report, 'project:work-project'
      expect(response).to include('Work Project')
    end

    it 'generates filtered period report' do
      response = dispatch_command :report, 'week', 'project:work-project'
      expect(response).to include('Work Project')
      expect(response).to include('неделю')
    end
  end

  context 'with options' do
    it 'generates detailed report' do
      response = dispatch_command :report, 'detailed'
      expect(response).to include('Детальный отчет')
    end

    it 'generates report grouped by day' do
      response = dispatch_command :report, 'week', 'by_day'
      # Проверяем наличие дат
    end
  end
end
```

### 4.3 Help система (0.5 дня)

#### Задачи по `/report help`

##### 4.3.1 Главная справка (0.2 дня)

**Задачи**:
- [ ] Создать класс `ReportHelpFormatter` для форматирования справки
- [ ] Реализовать главный экран справки с краткой информацией
- [ ] Добавить inline keyboard с кнопками разделов
- [ ] Интегрировать в ReportCommand
- [ ] Покрыть тестами

**Файлы для создания**:
```ruby
# app/services/report_help_formatter.rb
class ReportHelpFormatter
  def main_help
    # Главная справка с кнопками
  end

  def periods_help
    # Справка по периодам
  end

  def filters_help
    # Справка по фильтрам
  end

  def options_help
    # Справка по опциям
  end

  def examples_help
    # Примеры использования
  end

  private

  def main_keyboard
    # Inline keyboard для главной справки
  end

  def navigation_keyboard(section)
    # Навигационные кнопки для разделов
  end
end
```

**Интеграция в ReportCommand**:
```ruby
# app/commands/report_command.rb
class ReportCommand < BaseCommand
  def call!(*args)
    # Проверяем если первый аргумент - help
    if args.first == 'help'
      show_help
      return
    end

    # Обычная логика отчетов
    # ...
  end

  private

  def show_help
    help_formatter = ReportHelpFormatter.new
    text = help_formatter.main_help
    keyboard = help_formatter.main_keyboard

    respond_with :message,
                 text: text,
                 reply_markup: keyboard
  end
end
```

**Пример главной справки**:
```
📊 Команда /report - Универсальные отчеты

🎯 Быстрый старт:
• /report - отчет за сегодня
• /report week - за текущую неделю
• /report month - за текущий месяц

📅 Периоды:
today, yesterday, week, month, quarter
2024-01-15 или 2024-01-01:2024-01-31

🔍 Фильтры:
project:slug - один проект
projects:slug1,slug2 - несколько

⚙️ Опции:
detailed, by_day, by_project

💡 Примеры:
/report week project:work
/report month detailed
/report quarter by_project

❓ Старые команды продолжат работать
```

**Тесты**:
```ruby
# spec/services/report_help_formatter_spec.rb
RSpec.describe ReportHelpFormatter do
  describe '#main_help' do
    it 'returns main help text'
    it 'includes all sections'
    it 'contains emoji for readability'
  end

  describe '#main_keyboard' do
    it 'returns inline keyboard'
    it 'has 4 navigation buttons'
    it 'contains correct callback_data'
  end
end

# spec/commands/report_command_spec.rb
describe 'help command' do
  it 'responds to /report help' do
    response = dispatch_command :report, 'help'
    expect(response).to include('Универсальные отчеты')
    expect(response.dig(:reply_markup, :inline_keyboard)).not_to be_nil
  end
end
```

##### 4.3.2 Детальные разделы справки (0.2 дня)

**Задачи**:
- [ ] Реализовать раздел "📅 Периоды"
- [ ] Реализовать раздел "🔍 Фильтры"
- [ ] Реализовать раздел "⚙️ Опции"
- [ ] Реализовать раздел "💡 Примеры"
- [ ] Добавить навигацию между разделами
- [ ] Покрыть тестами

**Обработка callback_query**:
```ruby
# app/commands/report_command.rb
HELP_SECTIONS = {
  'help_periods' => :periods_help,
  'help_filters' => :filters_help,
  'help_options' => :options_help,
  'help_examples' => :examples_help,
  'help_main' => :main_help
}.freeze

def callback_query(data)
  return unless data.start_with?('report_help_')

  section = data.sub('report_help_', '')

  if HELP_SECTIONS.key?(section)
    help_formatter = ReportHelpFormatter.new
    text = help_formatter.send(HELP_SECTIONS[section])
    keyboard = help_formatter.navigation_keyboard(section)

    edit_message :text,
                 text: text,
                 reply_markup: keyboard
  end
end
```

**Пример раздела "Периоды"**:
```
📅 Периоды отчетов

Именованные периоды:
• today - сегодня (по умолчанию)
• yesterday - вчерашний день
• week - текущая неделя (пн-вс)
• month - текущий месяц
• quarter - последние 3 месяца

Конкретные даты:
• 2024-01-15 - один день
• 2024-01-01:2024-01-31 - диапазон

Примеры:
/report yesterday
/report week
/report 2024-01-01:2024-01-15
```

**Навигационные кнопки**:
```
[← Назад] [🔍 Фильтры] [💡 Примеры]
```

**Тесты**:
```ruby
describe 'help sections', :callback_query do
  context 'periods section' do
    let(:data) { 'report_help_periods' }

    it 'shows periods help' do
      response = dispatch(callback_query: {
        id: 'test',
        from: from,
        message: { message_id: 1, chat: chat },
        data: data
      })

      expect(response[:text]).to include('Периоды отчетов')
      expect(response[:text]).to include('today')
      expect(response[:text]).to include('week')
    end

    it 'has navigation keyboard' do
      response = dispatch(callback_query: {
        id: 'test',
        from: from,
        message: { message_id: 1, chat: chat },
        data: data
      })

      keyboard = response.dig(:reply_markup, :inline_keyboard)
      expect(keyboard).not_to be_nil
      expect(keyboard.flatten.map { |b| b[:text] }).to include('← Назад')
    end
  end

  context 'filters section' do
    let(:data) { 'report_help_filters' }

    it 'shows filters help'
    it 'has navigation keyboard'
  end

  context 'options section' do
    let(:data) { 'report_help_options' }

    it 'shows options help'
    it 'has navigation keyboard'
  end

  context 'examples section' do
    let(:data) { 'report_help_examples' }

    it 'shows examples help'
    it 'has navigation keyboard'
  end
end
```

##### 4.3.3 Интеграция callback_query (0.1 дня)

**Задачи**:
- [ ] Добавить обработку callback_query в ReportCommand
- [ ] Реализовать навигацию между разделами
- [ ] Добавить кнопку "Назад" к главной справке
- [ ] Покрыть интеграционными тестами

**Callback Query Routing**:
```ruby
# app/commands/report_command.rb
provides_context_methods BaseCommand::CONTEXT_METHODS

def callback_query(data)
  return unless data.start_with?('report_help_')

  section_name = data.sub('report_help_', '')
  show_help_section(section_name)
end

private

def show_help_section(section_name)
  help_formatter = ReportHelpFormatter.new

  case section_name
  when 'main'
    text = help_formatter.main_help
    keyboard = help_formatter.main_keyboard
  when 'periods'
    text = help_formatter.periods_help
    keyboard = help_formatter.section_keyboard('periods')
  when 'filters'
    text = help_formatter.filters_help
    keyboard = help_formatter.section_keyboard('filters')
  when 'options'
    text = help_formatter.options_help
    keyboard = help_formatter.section_keyboard('options')
  when 'examples'
    text = help_formatter.examples_help
    keyboard = help_formatter.section_keyboard('examples')
  else
    return
  end

  edit_message :text,
               text: text,
               reply_markup: keyboard
end
```

**Интеграционные тесты**:
```ruby
describe 'help navigation workflow', :callback_query do
  it 'navigates through all sections' do
    # 1. Открываем главную справку
    response = dispatch_command :report, 'help'
    expect(response[:text]).to include('Универсальные отчеты')

    # 2. Переходим в раздел "Периоды"
    response = dispatch(callback_query: {
      id: 'test',
      from: from,
      message: { message_id: 1, chat: chat },
      data: 'report_help_periods'
    })
    expect(response[:text]).to include('Периоды отчетов')

    # 3. Переходим в раздел "Фильтры"
    response = dispatch(callback_query: {
      id: 'test',
      from: from,
      message: { message_id: 1, chat: chat },
      data: 'report_help_filters'
    })
    expect(response[:text]).to include('Фильтры отчетов')

    # 4. Возвращаемся к главной справке
    response = dispatch(callback_query: {
      id: 'test',
      from: from,
      message: { message_id: 1, chat: chat },
      data: 'report_help_main'
    })
    expect(response[:text]).to include('Универсальные отчеты')
  end

  it 'navigates forward through sections' do
    # Периоды → Фильтры → Опции → Примеры → Главная
  end

  it 'navigates backward through sections' do
    # Примеры → Опции → Фильтры → Периоды → Главная
  end
end
```

**Критерий завершения**: Полностью функциональная интерактивная справка с навигацией

---

## Этап 5: Миграция старых команд (0.5 дня)

### 5.1 Рефакторинг DayCommand (0.1 дня)

#### Задачи
- [ ] Преобразовать DayCommand в алиас
- [ ] Добавить hint о новой команде
- [ ] Обновить тесты

**Пример реализации**:
```ruby
# app/commands/day_command.rb
class DayCommand < BaseCommand
  def call!(*args)
    # Делегируем в ReportCommand
    report_response = ReportCommand.new(controller).call!('today')

    # Добавляем hint
    hint = "\n\n💡 Теперь можно использовать /report today"

    # Модифицируем ответ (добавляем hint)
    respond_with :message, text: report_response[:text] + hint
  end
end
```

### 5.2 Рефакторинг SummaryCommand (0.1 дня)

#### Задачи
- [ ] Преобразовать SummaryCommand в алиас
- [ ] Поддержать существующий синтаксис `/summary {week|month}`
- [ ] Добавить hint
- [ ] Обновить тесты

### 5.3 Рефакторинг HoursCommand (0.2 дня)

#### Задачи
- [ ] Преобразовать HoursCommand в алиас
- [ ] Поддержать существующий синтаксис `/hours [project_slug]`
- [ ] Добавить hint
- [ ] Обновить тесты

### 5.4 Обновление существующего ReportCommand (0.1 дня)

#### Задачи
- [ ] Либо удалить старый ReportCommand, либо интегрировать его логику
- [ ] Обновить тесты

**Критерий завершения**: Все старые команды работают через новый ReportCommand

---

## Этап 6: Документация и релиз (0.5 дня)

### 6.1 Обновление документации (0.2 дня)

#### Задачи
- [ ] Обновить CLAUDE.md с описанием новой команды
- [ ] Добавить примеры использования
- [ ] Обновить список команд
- [ ] Создать migration guide для пользователей

**Файлы для обновления**:
- `CLAUDE.md`
- `README.md` (если есть раздел о командах)

### 6.2 Подготовка уведомления (0.1 дня)

#### Задачи
- [ ] Составить текст уведомления для пользователей
- [ ] Подготовить примеры использования
- [ ] Спланировать время отправки

**Пример уведомления**:
```
🎉 Обновление команд отчетов!

Теперь все отчеты доступны через одну команду /report:

📊 Примеры:
• /report - отчет за сегодня
• /report week - за неделю
• /report month - за месяц
• /report project:work-project - по проекту

💡 Больше возможностей:
• /report week detailed - детальный отчет
• /report month by_day - с разбивкой по дням
• /report quarter project:work - квартал по проекту

Старые команды (/day, /summary, /hours) продолжат работать, но мы рекомендуем перейти на новую.

❓ Подробная справка: /report help
```

### 6.3 Тестирование на staging (0.2 дня)

#### Задачи
- [ ] Развернуть на staging
- [ ] Провести полное тестирование всех сценариев
- [ ] Проверить производительность
- [ ] Исправить найденные баги

**Чек-лист тестирования**:
- [ ] Все периоды работают корректно
- [ ] Фильтры применяются правильно
- [ ] Форматирование корректно
- [ ] Help система (`/report help`) работает
- [ ] Навигация между разделами справки работает
- [ ] Inline keyboard кнопки корректны
- [ ] Старые команды работают
- [ ] Hints показываются
- [ ] Нет ошибок в логах

**Критерий завершения**: Готово к релизу в продакшен

---

## Чек-лист готовности к релизу

### Код
- [ ] Все тесты проходят (покрытие > 90%)
- [ ] Rubocop проверки пройдены
- [ ] Brakeman не находит уязвимостей
- [ ] Code review выполнен

### Тестирование
- [ ] Unit тесты для всех классов
- [ ] Интеграционные тесты для команд
- [ ] Тестирование на staging пройдено
- [ ] Performance тестирование выполнено

### Документация
- [ ] CLAUDE.md обновлен
- [ ] Migration guide создан
- [ ] Help команда обновлена
- [ ] Changelog обновлен

### Релиз
- [ ] Уведомление для пользователей готово
- [ ] План отката подготовлен
- [ ] Мониторинг настроен
- [ ] Дата релиза согласована

---

## Rollback план

### Сценарий 1: Критические баги в новом ReportCommand

**Действия**:
1. Откатить ReportCommand к предыдущей версии
2. Восстановить старые команды
3. Уведомить пользователей о временных проблемах

**Время**: 15 минут

### Сценарий 2: Проблемы с производительностью

**Действия**:
1. Откатить изменения
2. Оптимизировать запросы
3. Повторно развернуть после исправления

**Время**: 30 минут

### Сценарий 3: Негативные отзывы пользователей

**Действия**:
1. Собрать обратную связь
2. Внести необходимые изменения
3. Повторно развернуть улучшенную версию

**Время**: 1-2 дня

---

## Метрики для мониторинга

### Технические метрики
- Время ответа команды `/report` (цель: < 2 сек)
- Количество ошибок (цель: 0 в первую неделю)
- Загрузка БД (мониторить slow queries)

### Бизнес метрики
- Процент использования новой команды vs старых
- Количество уникальных пользователей команды
- Распределение по типам отчетов (today/week/month)
- Использование `/report help` (количество вызовов, популярные разделы)

### Метрики качества
- Количество багов в первую неделю (цель: < 3)
- Количество запросов в поддержку (должно снизиться)
- Оценка пользователей (собирать через опросы)

---

## Заметки по реализации

### Оптимизация производительности
- Использовать `includes(:project, :user)` для eager loading
- Кешировать результаты для часто запрашиваемых периодов
- Добавить индексы на `date` и `project_id` если их нет

### Best practices
- Использовать service objects для бизнес-логики
- Держать команды тонкими (только парсинг и делегирование)
- Покрывать edge cases тестами
- Логировать все ошибки для дальнейшего анализа

### Известные ограничения
- Максимальный период запроса не ограничен (может быть медленно для больших диапазонов)
- Форматирование может обрезаться при очень большом количестве записей (лимит Telegram ~4096 символов)

---

## Контакты и ответственные

**Product Owner**: TBD
**Tech Lead**: TBD
**Developer**: TBD
**QA**: TBD

## История изменений плана

| Дата | Версия | Изменения |
|------|--------|-----------|
| 2025-01-13 | 1.0 | Первая версия плана |
| 2025-01-13 | 1.1 | Добавлен раздел 4.3 "Help система" с детальными задачами по реализации `/report help`. Общее время увеличено до 5.2 дней |
