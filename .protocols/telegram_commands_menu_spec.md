# Спецификация: Автоматическая установка меню команд Telegram бота

## Цель
Создать систему автоматической установки списка команд Telegram бота через API `setMyCommands`, которая:
- Автоматически обнаруживает команды из реестра (`app/commands/`)
- Исключает команды доступные только разработчику
- Использует локализованные описания команд
- Легко поддерживается и расширяется

## Контекст

### Проблема
В данный момент при вводе `/` в Telegram боте пользователь не видит подсказок с доступными командами. Это ухудшает UX и затрудняет обнаружение функциональности бота.

### Решение
Использовать метод Telegram Bot API `setMyCommands` для установки списка команд с описаниями.

## Требования

### Функциональные требования

#### FR-1: Метаданные команд
**Приоритет**: Критичный

Каждый класс команды должен иметь возможность декларировать свои метаданные:

```ruby
class AddCommand < BaseCommand
  # Метаданные команды
  command_metadata(
    developer_only: false  # Флаг доступа (опционально, по умолчанию false)
  )

  def call(*args)
    # Логика команды
  end
end
```

**Автоматическое вычисление ключа I18n**:
- Ключ перевода вычисляется автоматически: `telegram.commands.descriptions.#{command_name}`
- Для `AddCommand` → `telegram.commands.descriptions.add`
- Для `NotifyCommand` → `telegram.commands.descriptions.notify`

**Автоматическая проверка доступа**:
- Если команда помечена `developer_only: true`, то `safe_call` автоматически проверяет `developer?`
- При отказе в доступе возвращается локализованная ошибка из `telegram.errors.developer_access_denied`
- Команды больше НЕ нужно вручную проверять `developer?` в методе `call`

**Критерии приемки**:
- [ ] Метод класса `command_metadata` доступен для всех команд
- [ ] Поддерживается параметр `developer_only` (boolean, по умолчанию false)
- [ ] Ключ I18n автоматически вычисляется по имени класса команды
- [ ] Метод `command_description_key` возвращает вычисленный ключ I18n
- [ ] `safe_call` автоматически проверяет `developer?` для команд с `developer_only: true`
- [ ] При отказе в доступе показывается локализованная ошибка

#### FR-2: Реестр команд
**Приоритет**: Критичный

Создать модуль `Telegram::CommandRegistry`, который:
- Автоматически сканирует `app/commands/` для поиска команд
- Предоставляет методы для получения списка команд
- Фильтрует команды по критериям (developer_only, has_description)

```ruby
module Telegram
  module CommandRegistry
    # Все команды с метаданными
    def self.all_commands
      # => [AddCommand, StartCommand, NotifyCommand, ...]
    end

    # Команды для публичного меню (исключая developer_only)
    def self.public_commands
      # => [AddCommand, StartCommand, HelpCommand, ...]
    end

    # Команды с описаниями
    def self.commands_with_descriptions
      # => [AddCommand, StartCommand, ...]
    end

    # Команды только для разработчика
    def self.developer_commands
      # => [NotifyCommand, ...]
    end

    # Название команды из класса (AddCommand -> 'add')
    def self.command_name(command_class)
      # => 'add'
    end
  end
end
```

**Критерии приемки**:
- [ ] Реестр автоматически находит все классы команд в `app/commands/`
- [ ] Методы фильтрации работают корректно
- [ ] Поддержка получения названия команды из класса
- [ ] Исключение `BaseCommand` из списка команд

#### FR-3: Rake-задача установки команд
**Приоритет**: Критичный

Создать `lib/tasks/telegram.rake` с задачей установки команд:

```ruby
namespace :telegram do
  namespace :bot do
    desc 'Set bot commands menu for all users'
    task set_commands: :environment do
      commands = Telegram::CommandRegistry.public_commands
        .map do |cmd|
          command_name = Telegram::CommandRegistry.command_name(cmd)
          description_key = "telegram.commands.descriptions.#{command_name}"

          {
            command: command_name,
            description: I18n.t(description_key, default: command_name.humanize)
          }
        end

      Telegram.bots[:default].set_my_commands(commands: commands)
      puts "✅ Commands set successfully! (#{commands.size} commands)"

      # Вывод установленных команд
      commands.each do |cmd|
        puts "  /#{cmd[:command]} - #{cmd[:description]}"
      end
    end
  end
end
```

**Критерии приемки**:
- [ ] Задача `rake telegram:bot:set_commands` успешно выполняется
- [ ] Команды устанавливаются через API `setMyCommands`
- [ ] Все публичные команды включаются в меню (с переводом или дефолтным описанием)
- [ ] Используется `I18n.t(key, default: ...)` для автоматического fallback
- [ ] Вывод информирует о количестве установленных команд
- [ ] Команды выводятся в консоль для проверки

#### FR-4: Локализация описаний команд
**Приоритет**: Критичный

Добавить описания команд в `config/locales/ru.yml`:

```yaml
ru:
  telegram:
    commands:
      descriptions:
        start: "Начать работу с ботом"
        help: "Показать справку по командам"
        add: "Добавить запись времени"
        projects: "Управление проектами"
        clients: "Управление клиентами"
        report: "Отчеты по времени"
        users: "Управление пользователями проекта"
        rate: "Установить ставку для проекта"
        edit: "Редактировать записи времени"
        merge: "Объединить записи времени"
        reset: "Сбросить данные"
        version: "Версия бота"
        # developer_only команды НЕ включаются в публичное меню
        # notify: "Отправить уведомление всем пользователям"
```

**Критерии приемки**:
- [ ] Все публичные команды имеют описания
- [ ] Описания на русском языке
- [ ] Длина описания не превышает 256 символов (ограничение API)
- [ ] Команды только для разработчиков закомментированы или помечены

### Нефункциональные требования

#### NFR-1: Расширяемость
- Новые команды автоматически добавляются в реестр при создании файла в `app/commands/`
- Метаданные легко расширяются новыми полями

#### NFR-2: Производительность
- Реестр команд кешируется в production (опционально)
- Rake-задача выполняется быстро (<5 секунд)

#### NFR-3: Безопасность
- Команды разработчика никогда не попадают в публичное меню
- Проверка доступа к командам остается в логике команд (не меняется)

## Архитектура решения

### Компоненты

1. **BaseCommand** (`app/commands/base_command.rb`)
   - Добавление методов класса `command_metadata`, `command_description_key`, `developer_only?`
   - Модификация метода `safe_call` для автоматической проверки `developer?`
   - Централизованная логика проверки доступа для developer_only команд

**Реализация автоматической проверки в BaseCommand**:
```ruby
# app/commands/base_command.rb
class BaseCommand
  # Метаданные команды
  def self.command_metadata(developer_only: false)
    @developer_only = developer_only
  end

  def self.developer_only?
    @developer_only || false
  end

  def self.command_description_key
    command_name = name.underscore.sub(/_command$/, '')
    "telegram.commands.descriptions.#{command_name}"
  end

  # Модифицированный safe_call с автоматической проверкой
  def safe_call(*args)
    Rails.logger.info "#{self.class}.call with args #{args}"

    # Автоматическая проверка для developer_only команд
    if self.class.developer_only? && !developer?
      return respond_with :message, text: t('telegram.errors.developer_access_denied')
    end

    call(*args)
  end

  # ... остальной код
end
```

2. **Telegram::CommandRegistry** (`lib/telegram/command_registry.rb`)
   - Сканирование и регистрация команд
   - Фильтрация по критериям
   - Утилиты для работы с командами

3. **Rake Task** (`lib/tasks/telegram.rake`)
   - Интерфейс для установки команд
   - Вызов Telegram Bot API

4. **Локализация** (`config/locales/ru.yml`)
   - Описания команд на русском языке
   - Сообщение об ошибке доступа для developer_only команд

### Диаграмма потока данных

```
app/commands/*.rb
     ↓
Telegram::CommandRegistry.all_commands
     ↓
Telegram::CommandRegistry.public_commands (фильтр developer_only)
     ↓
commands_with_descriptions (фильтр has_description)
     ↓
I18n.t(description_key) для каждой команды
     ↓
Telegram.bots[:default].set_my_commands(commands: [...])
     ↓
Telegram Bot API setMyCommands
```

## Примеры использования

### Добавление новой команды

```ruby
# app/commands/stats_command.rb
class StatsCommand < BaseCommand
  # Метаданные команды (опционально, если developer_only не нужен)
  # command_metadata(developer_only: false)
  # По умолчанию developer_only = false, можно не указывать

  def call(*args)
    # Логика команды
  end
end
```

```yaml
# config/locales/ru.yml
ru:
  telegram:
    commands:
      descriptions:
        stats: "Статистика по проектам"
        # Ключ автоматически вычисляется: telegram.commands.descriptions.stats
```

```bash
# Установка обновленного меню команд
bundle exec rake telegram:bot:set_commands
```

### Команда только для разработчика

```ruby
# app/commands/debug_command.rb
class DebugCommand < BaseCommand
  command_metadata(
    developer_only: true  # НЕ попадет в публичное меню
  )

  def call(*args)
    # Проверка developer? НЕ нужна - она автоматическая в safe_call!
    # BaseCommand автоматически проверит доступ для developer_only команд

    # Логика команды
    respond_with :message, text: "Отладочная информация: ..."
  end
end
```

```yaml
# config/locales/ru.yml
ru:
  telegram:
    errors:
      developer_access_denied: "🚫 Доступ запрещён. Команда доступна только разработчику."
    commands:
      descriptions:
        # debug: "Отладочная информация" - НЕ добавляем, т.к. developer_only
```

**До и после**:
```ruby
# ДО (ручная проверка)
class NotifyCommand < BaseCommand
  def call
    return respond_with :message, text: 'Доступ запрещен' unless developer?
    # Логика...
  end
end

# ПОСЛЕ (автоматическая проверка)
class NotifyCommand < BaseCommand
  command_metadata(developer_only: true)

  def call
    # Проверка developer? больше не нужна!
    # Логика...
  end
end
```

## Тестирование

### Unit-тесты

```ruby
# spec/lib/telegram/command_registry_spec.rb
RSpec.describe Telegram::CommandRegistry do
  describe '.all_commands' do
    it 'returns all command classes' do
      commands = described_class.all_commands
      expect(commands).to include(AddCommand, StartCommand, NotifyCommand)
      expect(commands).not_to include(BaseCommand)
    end
  end

  describe '.public_commands' do
    it 'excludes developer_only commands' do
      commands = described_class.public_commands
      expect(commands).to include(AddCommand)
      expect(commands).not_to include(NotifyCommand) # developer_only
    end
  end

  describe '.command_name' do
    it 'extracts command name from class' do
      expect(described_class.command_name(AddCommand)).to eq('add')
      expect(described_class.command_name(StartCommand)).to eq('start')
    end
  end
end
```

### Integration-тесты

```ruby
# spec/tasks/telegram_rake_spec.rb
RSpec.describe 'telegram:bot:set_commands' do
  it 'sets commands via Telegram API' do
    allow(Telegram.bots[:default]).to receive(:set_my_commands)

    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands).with(
      commands: array_including(
        hash_including(command: 'add', description: String),
        hash_including(command: 'start', description: String)
      )
    )
  end

  it 'excludes developer_only commands' do
    allow(Telegram.bots[:default]).to receive(:set_my_commands)

    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands).with(
      commands: array_excluding(
        hash_including(command: 'notify')
      )
    )
  end
end
```

## Миграция существующих команд

### Этап 1: Добавить метаданные в команды только для разработчика

Команды по умолчанию публичные (`developer_only: false`), поэтому метаданные нужно добавить только в команды для разработчика:

```ruby
# ДО
class NotifyCommand < BaseCommand
  def call
    return respond_with :message, text: 'Доступ запрещен' unless developer?
    # ...
  end
end

# ПОСЛЕ
class NotifyCommand < BaseCommand
  command_metadata(developer_only: true)

  def call
    return respond_with :message, text: 'Доступ запрещен' unless developer?
    # ...
  end
end
```

Публичные команды не требуют явного указания `command_metadata` (если нет особых требований).

### Этап 2: Добавить описания в локализацию

### Этап 3: Запустить rake-задачу

```bash
bundle exec rake telegram:bot:set_commands
```

## Риски и ограничения

### Ограничения Telegram Bot API
- Максимум 100 команд
- Описание команды до 256 символов
- Название команды: 1-32 символа, латиница, цифры, подчеркивания

### Риски
1. **Отсутствие перевода команды**: Команда без перевода в I18n отображается с дефолтным описанием
   - Решение: Используется `I18n.t(key, default: command_name.humanize)` для автоматического fallback
   - Пример: команда `add` без перевода → дефолтное описание "Add"

2. **Изменение API Telegram**: Breaking changes в `setMyCommands`
   - Решение: Мониторинг changelog Telegram Bot API

## Дальнейшие улучшения

### Версия 2.0
- [ ] Поддержка multiple языков (scope + language_code)
- [ ] Разные команды для разных scope (personal, group, channel)
- [ ] Автоматическое обновление команд при деплое
- [ ] Валидация длины описаний команд
- [ ] Кеширование реестра команд в production

### Версия 3.0
- [ ] Динамические команды (включение/выключение через админ-панель)
- [ ] A/B тестирование команд
- [ ] Аналитика использования команд

## План имплементации

### Этап 1: Подготовка BaseCommand (Фундамент)
**Приоритет**: Критичный | **Время**: 30 мин

#### 1.1. Добавить методы метаданных в BaseCommand
**Файл**: `app/commands/base_command.rb`

```ruby
class BaseCommand
  # Добавить после существующих методов класса

  # Метаданные команды
  def self.command_metadata(developer_only: false)
    @developer_only = developer_only
  end

  def self.developer_only?
    @developer_only || false
  end

  def self.command_description_key
    command_name = name.underscore.sub(/_command$/, '')
    "telegram.commands.descriptions.#{command_name}"
  end
end
```

**Проверка**:
```ruby
# rails console
NotifyCommand.developer_only?  # должно быть false (пока не добавили metadata)
AddCommand.command_description_key  # => "telegram.commands.descriptions.add"
```

#### 1.2. Модифицировать safe_call для автоматической проверки
**Файл**: `app/commands/base_command.rb`

```ruby
def safe_call(*args)
  Rails.logger.info "#{self.class}.call with args #{args}"

  # Автоматическая проверка для developer_only команд
  if self.class.developer_only? && !developer?
    return respond_with :message, text: t('telegram.errors.developer_access_denied')
  end

  call(*args)
end
```

**Проверка**:
- Запустить существующие тесты: `bundle exec rspec spec/commands/`
- Все тесты должны проходить (поведение не изменилось)

---

### Этап 2: Реестр команд (Core Logic)
**Приоритет**: Критичный | **Время**: 45 мин

#### 2.1. Создать Telegram::CommandRegistry
**Файл**: `lib/telegram/command_registry.rb`

```ruby
# frozen_string_literal: true

module Telegram
  module CommandRegistry
    class << self
      # Все классы команд (исключая BaseCommand)
      def all_commands
        @all_commands ||= begin
          # Загружаем все файлы команд
          Dir[Rails.root.join('app/commands/*_command.rb')].each { |f| require_dependency f }

          # Получаем все классы, наследующиеся от BaseCommand
          ObjectSpace.each_object(Class)
            .select { |klass| klass < BaseCommand && klass != BaseCommand }
        end
      end

      # Публичные команды (исключая developer_only)
      def public_commands
        all_commands.reject(&:developer_only?)
      end

      # Команды только для разработчиков
      def developer_commands
        all_commands.select(&:developer_only?)
      end

      # Получить название команды из класса
      # AddCommand -> 'add'
      # NotifyCommand -> 'notify'
      def command_name(command_class)
        command_class.name.underscore.sub(/_command$/, '')
      end

      # Сброс кеша (для тестов)
      def reset!
        @all_commands = nil
      end
    end
  end
end
```

**Проверка**:
```ruby
# rails console
Telegram::CommandRegistry.all_commands.count  # должно быть ~17
Telegram::CommandRegistry.public_commands.count  # должно быть ~16 (без notify)
Telegram::CommandRegistry.command_name(AddCommand)  # => "add"
```

#### 2.2. Добавить автозагрузку модуля
**Файл**: `config/application.rb`

Проверить что есть строка:
```ruby
config.autoload_paths << Rails.root.join('lib')
```

Если нет - добавить.

---

### Этап 3: Локализация (Translations)
**Приоритет**: Критичный | **Время**: 20 мин

#### 3.1. Добавить описания команд
**Файл**: `config/locales/ru.yml`

```yaml
ru:
  telegram:
    errors:
      developer_access_denied: "🚫 Доступ запрещён. Команда доступна только разработчику."

    commands:
      descriptions:
        start: "Начать работу с ботом"
        help: "Показать справку по командам"
        add: "Добавить запись времени"
        projects: "Управление проектами"
        clients: "Управление клиентами"
        report: "Отчеты по времени"
        users: "Управление пользователями проекта"
        rate: "Установить ставку для проекта"
        edit: "Редактировать записи времени"
        merge: "Объединить пользователей (разработчик)"
        reset: "Сбросить данные"
        attach: "Привязать Telegram к аккаунту"
        version: "Версия бота"
        day: "Отчет за день (устарела, см. /report)"
        hours: "Отчет за квартал (устарела, см. /report)"
        summary: "Сводный отчет (устарела, см. /report)"
        # notify - НЕ добавляем, т.к. developer_only
```

**Проверка**:
```ruby
# rails console
I18n.t('telegram.commands.descriptions.add')  # => "Добавить запись времени"
I18n.t('telegram.errors.developer_access_denied')  # => "🚫 Доступ запрещён..."
```

---

### Этап 4: Rake-задача (Deployment Tool)
**Приоритет**: Критичный | **Время**: 15 мин

#### 4.1. Создать rake-задачу
**Файл**: `lib/tasks/telegram.rake`

```ruby
# frozen_string_literal: true

namespace :telegram do
  namespace :bot do
    desc 'Set bot commands menu for all users'
    task set_commands: :environment do
      commands = Telegram::CommandRegistry.public_commands
        .map do |cmd|
          command_name = Telegram::CommandRegistry.command_name(cmd)
          description_key = "telegram.commands.descriptions.#{command_name}"

          {
            command: command_name,
            description: I18n.t(description_key, default: command_name.humanize)
          }
        end

      Telegram.bots[:default].set_my_commands(commands: commands)

      puts "✅ Commands set successfully! (#{commands.size} commands)"
      puts ""
      puts "📋 Installed commands:"
      commands.each do |cmd|
        puts "  /#{cmd[:command]} - #{cmd[:description]}"
      end
    end
  end
end
```

**Проверка**:
```bash
bundle exec rake telegram:bot:set_commands
# Должен вывести список команд и успешно завершиться
```

---

### Этап 5: Маркировка developer_only команд (Metadata)
**Приоритет**: Высокий | **Время**: 10 мин

#### 5.1. Добавить метаданные в NotifyCommand
**Файл**: `app/commands/notify_command.rb`

```ruby
class NotifyCommand < BaseCommand
  command_metadata(developer_only: true)  # ДОБАВИТЬ ЭТУ СТРОКУ

  MIN_MESSAGE_LENGTH = 3
  MAX_MESSAGE_LENGTH = 4000

  # Shortcut for telegram command translations
  def t(key, **options)
    super("telegram.#{key}", **options)
  end

  provides_context_methods NOTIFY_MESSAGE_INPUT

  def call
    # УБРАТЬ эту проверку - она теперь автоматическая в safe_call
    # return respond_with :message, text: t('commands.notify.errors.access_denied') unless developer?

    save_context NOTIFY_MESSAGE_INPUT
    respond_with :message, text: t('commands.notify.prompts.enter_message')
  end

  # ... остальной код без изменений
end
```

#### 5.2. Добавить метаданные в MergeCommand
**Файл**: `app/commands/merge_command.rb`

```ruby
class MergeCommand < BaseCommand
  command_metadata(developer_only: true)  # ДОБАВИТЬ ЭТУ СТРОКУ

  def call(email = nil, telegram_username = nil, *)
    # УБРАТЬ эту проверку - она теперь автоматическая в safe_call
    # unless developer?
    #   respond_with :message, text: 'Эта команда доступна только разработчику системы'
    #   return
    # end

    if email.blank? || telegram_username.blank?
      respond_with :message, text: 'Использование: /merge email@example.com telegram_username'
      return
    end

    TelegramUserMerger.new(email, telegram_username, controller: controller).merge
  end
end
```

#### 5.3. Обновить UsersCommand (частичный developer_only)
**Файл**: `app/commands/users_command.rb`

**ВНИМАНИЕ**: Эта команда имеет метод `del!` только для разработчика, но другие методы публичные.

**Решение**: Оставить проверку `developer?` внутри метода `del!` как есть, не добавлять `command_metadata(developer_only: true)` на весь класс.

```ruby
class UsersCommand < BaseCommand
  # НЕ добавляем command_metadata(developer_only: true)
  # потому что только del! требует developer доступа

  def del!(username)
    # Оставляем эту проверку как есть
    return respond_with :message, text: 'Эта команда доступна только разработчику системы' unless developer?
    # ... остальной код
  end

  # ... остальные методы публичные
end
```

**Проверка**:
```bash
# Запустить тесты команд
bundle exec rspec spec/commands/notify_command_spec.rb
bundle exec rspec spec/commands/merge_command_spec.rb
```

---

### Этап 6: Тестирование (Quality Assurance)
**Приоритет**: Высокий | **Время**: 60 мин

#### 6.1. Unit-тесты для CommandRegistry
**Файл**: `spec/lib/telegram/command_registry_spec.rb`

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::CommandRegistry do
  describe '.all_commands' do
    it 'returns all command classes' do
      commands = described_class.all_commands

      expect(commands).to include(AddCommand, StartCommand, NotifyCommand, HelpCommand)
      expect(commands).not_to include(BaseCommand)
      expect(commands.all? { |c| c < BaseCommand }).to be true
    end

    it 'returns at least 15 commands' do
      expect(described_class.all_commands.size).to be >= 15
    end
  end

  describe '.public_commands' do
    it 'excludes developer_only commands' do
      commands = described_class.public_commands

      expect(commands).to include(AddCommand, StartCommand, HelpCommand)
      expect(commands).not_to include(NotifyCommand) # developer_only
    end
  end

  describe '.developer_commands' do
    it 'includes only developer_only commands' do
      commands = described_class.developer_commands

      expect(commands).to include(NotifyCommand, MergeCommand)
      expect(commands).not_to include(AddCommand, StartCommand)
    end
  end

  describe '.command_name' do
    it 'extracts command name from class' do
      expect(described_class.command_name(AddCommand)).to eq('add')
      expect(described_class.command_name(StartCommand)).to eq('start')
      expect(described_class.command_name(NotifyCommand)).to eq('notify')
    end
  end
end
```

#### 6.2. Integration-тесты для rake-задачи
**Файл**: `spec/tasks/telegram_rake_spec.rb`

```ruby
# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'telegram:bot:set_commands' do
  before do
    Rails.application.load_tasks
    allow(Telegram.bots[:default]).to receive(:set_my_commands)
  end

  it 'sets commands via Telegram API' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands).with(
      commands: array_including(
        hash_including(command: 'add', description: String),
        hash_including(command: 'start', description: String),
        hash_including(command: 'help', description: String)
      )
    )
  end

  it 'excludes developer_only commands' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands) do |args|
      command_names = args[:commands].map { |c| c[:command] }
      expect(command_names).not_to include('notify', 'merge')
    end
  end

  it 'includes all public commands' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands) do |args|
      expect(args[:commands].size).to be >= 14
    end
  end
end
```

#### 6.3. Тесты для BaseCommand с developer_only
**Файл**: `spec/commands/base_command_spec.rb`

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseCommand do
  let(:controller) { double('controller', developer?: false, respond_with: true, t: 'translated') }

  describe '.command_metadata' do
    it 'sets developer_only flag' do
      test_class = Class.new(BaseCommand) do
        command_metadata(developer_only: true)
      end

      expect(test_class.developer_only?).to be true
    end

    it 'defaults developer_only to false' do
      test_class = Class.new(BaseCommand)

      expect(test_class.developer_only?).to be false
    end
  end

  describe '.command_description_key' do
    it 'generates I18n key from class name' do
      stub_const('TestCommand', Class.new(BaseCommand))

      expect(TestCommand.command_description_key).to eq('telegram.commands.descriptions.test')
    end
  end

  describe '#safe_call' do
    context 'when command is developer_only' do
      let(:developer_command_class) do
        Class.new(BaseCommand) do
          command_metadata(developer_only: true)

          def call(*args)
            # Mock implementation
          end
        end
      end

      it 'blocks non-developers' do
        command = developer_command_class.new(controller)

        command.safe_call('arg1', 'arg2')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'translated'
        )
      end

      it 'allows developers' do
        allow(controller).to receive(:developer?).and_return(true)
        command = developer_command_class.new(controller)
        allow(command).to receive(:call)

        command.safe_call('arg1', 'arg2')

        expect(command).to have_received(:call).with('arg1', 'arg2')
      end
    end

    context 'when command is public' do
      let(:public_command_class) do
        Class.new(BaseCommand) do
          def call(*args)
            # Mock implementation
          end
        end
      end

      it 'allows all users' do
        command = public_command_class.new(controller)
        allow(command).to receive(:call)

        command.safe_call('arg1')

        expect(command).to have_received(:call).with('arg1')
      end
    end
  end
end
```

**Запуск тестов**:
```bash
bundle exec rspec spec/lib/telegram/command_registry_spec.rb
bundle exec rspec spec/tasks/telegram_rake_spec.rb
bundle exec rspec spec/commands/base_command_spec.rb
```

---

### Этап 7: Финальная проверка (Verification)
**Приоритет**: Критичный | **Время**: 30 мин

#### 7.1. Запустить все тесты
```bash
bundle exec rspec
```

#### 7.2. Проверить в development окружении
```bash
# Запустить rake-задачу
bundle exec rake telegram:bot:set_commands

# Проверить вывод - должны быть все публичные команды
# Не должно быть: notify, merge (если отмечены developer_only)
```

#### 7.3. Проверить в Telegram
1. Открыть бота в Telegram
2. Начать печатать `/`
3. Проверить что отображается список команд с описаниями
4. Проверить что команды `notify` и `merge` НЕ отображаются в меню

#### 7.4. Проверить доступ к developer_only командам
```bash
# Тест 1: Обычный пользователь не может вызвать /notify
# Должна быть ошибка: "🚫 Доступ запрещён. Команда доступна только разработчику."

# Тест 2: Разработчик может вызвать /notify
# Должно показать промпт: "📝 Введите текст уведомления (или 'cancel' для отмены):"
```

---

### Этап 8: Production Deployment
**Приоритет**: Критичный | **Время**: 15 мин

#### 8.1. Создать changelog entry
**Файл**: `CHANGELOG.md`

```markdown
## [Unreleased]

### Added
- Автоматическое меню команд Telegram бота через `setMyCommands` API
- Реестр команд `Telegram::CommandRegistry` для автоматического обнаружения команд
- Автоматическая проверка доступа для `developer_only` команд в `BaseCommand`
- Rake-задача `telegram:bot:set_commands` для установки меню команд
- Описания команд в локализации (`telegram.commands.descriptions.*`)

### Changed
- `NotifyCommand` и `MergeCommand` теперь автоматически проверяют доступ через `developer_only: true`
- Убраны ручные проверки `developer?` из `NotifyCommand` и `MergeCommand`
```

#### 8.2. Обновить CLAUDE.md
**Файл**: `CLAUDE.md`

Добавить в раздел "Development Commands":

```markdown
### Telegram Bot Commands

```bash
bundle exec rake telegram:bot:set_commands  # Установить меню команд бота
```

The bot commands menu will be automatically shown when users type `/` in Telegram.

Commands are automatically discovered from `app/commands/` directory.
- Public commands are shown in the menu
- Developer-only commands (marked with `developer_only: true`) are hidden from the menu
- Command descriptions are in `config/locales/ru.yml` under `telegram.commands.descriptions.*`
```

#### 8.3. Deploy to production
```bash
# 1. Запушить изменения
git add .
git commit -m "feat: Add automatic Telegram bot commands menu"
git push

# 2. После деплоя на production - установить команды
# SSH to production server
bundle exec rake telegram:bot:set_commands RAILS_ENV=production

# 3. Проверить в production Telegram боте
# Открыть бота, ввести `/` - должны отображаться команды
```

---

## Чеклист имплементации

### Обязательные задачи
- [ ] Этап 1.1: Добавить методы метаданных в BaseCommand
- [ ] Этап 1.2: Модифицировать safe_call для автоматической проверки
- [ ] Этап 2.1: Создать Telegram::CommandRegistry
- [ ] Этап 2.2: Проверить автозагрузку lib/
- [ ] Этап 3.1: Добавить описания команд в ru.yml
- [ ] Этап 4.1: Создать rake-задачу telegram:bot:set_commands
- [ ] Этап 5.1: Добавить метаданные в NotifyCommand
- [ ] Этап 5.2: Добавить метаданные в MergeCommand
- [ ] Этап 5.3: Проверить UsersCommand
- [ ] Этап 6.1: Unit-тесты для CommandRegistry
- [ ] Этап 6.2: Integration-тесты для rake-задачи
- [ ] Этап 6.3: Тесты для BaseCommand
- [ ] Этап 7.1: Запустить все тесты
- [ ] Этап 7.2: Проверить в development
- [ ] Этап 7.3: Проверить в Telegram
- [ ] Этап 7.4: Проверить доступ к developer_only
- [ ] Этап 8.1: Создать changelog entry
- [ ] Этап 8.2: Обновить CLAUDE.md
- [ ] Этап 8.3: Deploy to production

### Опциональные улучшения
- [ ] Добавить кеширование реестра команд в production
- [ ] Добавить валидацию длины описаний (max 256 символов)
- [ ] Добавить rake-задачу для проверки всех переводов
- [ ] Добавить мониторинг успешности установки команд

---

## Оценка времени

| Этап | Время | Критичность |
|------|-------|-------------|
| Этап 1: BaseCommand | 30 мин | Критично |
| Этап 2: CommandRegistry | 45 мин | Критично |
| Этап 3: Локализация | 20 мин | Критично |
| Этап 4: Rake-задача | 15 мин | Критично |
| Этап 5: Метаданные команд | 10 мин | Высоко |
| Этап 6: Тестирование | 60 мин | Высоко |
| Этап 7: Проверка | 30 мин | Критично |
| Этап 8: Deployment | 15 мин | Критично |
| **Итого** | **~3.5 часа** | |

---

## Критерии готовности (Definition of Done)

- [ ] Реализован модуль `Telegram::CommandRegistry`
- [ ] Добавлен метод `command_metadata` в `BaseCommand`
- [ ] Созданы метаданные для всех существующих команд
- [ ] Добавлены описания в `config/locales/ru.yml`
- [ ] Создана rake-задача `telegram:bot:set_commands`
- [ ] Написаны unit-тесты для реестра команд
- [ ] Написаны integration-тесты для rake-задачи
- [ ] Задача успешно выполнена в development окружении
- [ ] Задача успешно выполнена в production окружении
- [ ] Команды отображаются в Telegram при вводе `/`
- [ ] Обновлена документация в CLAUDE.md
- [ ] Создан changelog entry

## Приложения

### Приложение A: Список всех команд проекта

```
Публичные команды (попадают в меню):
- start     - Начать работу с ботом
- help      - Показать справку по командам
- add       - Добавить запись времени
- projects  - Управление проектами
- clients   - Управление клиентами
- report    - Отчеты по времени
- users     - Управление пользователями проекта
- rate      - Установить ставку для проекта
- edit      - Редактировать записи времени
- merge     - Объединить записи времени
- reset     - Сбросить данные
- version   - Версия бота
- day       - (deprecated, см. report)
- hours     - (deprecated, см. report)
- summary   - (deprecated, см. report)
- attach    - Привязать Telegram к аккаунту

Команды только для разработчика (НЕ попадают в меню):
- notify    - Отправить уведомление всем пользователям
```

### Приложение B: Пример вызова setMyCommands

```ruby
commands = [
  { command: 'start', description: 'Начать работу с ботом' },
  { command: 'help', description: 'Показать справку по командам' },
  { command: 'add', description: 'Добавить запись времени' },
  # ... остальные команды
]

Telegram.bots[:default].set_my_commands(commands: commands)
# => true (успешно)
```

### Приложение C: Структура файлов

```
app/
  commands/
    base_command.rb          # +command_metadata метод
    add_command.rb           # +metadata
    start_command.rb         # +metadata
    notify_command.rb        # +metadata (developer_only: true)
    ...

lib/
  telegram/
    command_registry.rb      # NEW: реестр команд
  tasks/
    telegram.rake            # NEW: rake задачи

config/
  locales/
    ru.yml                   # +descriptions для команд

spec/
  lib/
    telegram/
      command_registry_spec.rb  # NEW: тесты реестра
  tasks/
    telegram_rake_spec.rb       # NEW: тесты rake-задачи
```

## Ссылки

- [Telegram Bot API - setMyCommands](https://core.telegram.org/bots/api#setmycommands)
- [Telegram Bot Features - Commands](https://core.telegram.org/bots/features#commands)
- [telegram-bot gem Documentation](https://github.com/telegram-bot-rb/telegram-bot)
