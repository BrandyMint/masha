# План имплементации команды /rate

## Обзор

План реализации функционала установки почасовых ставок участников проекта через Telegram бота на основе спецификации.

## Этапы реализации

### Этап 1: Подготовка базы данных (0.5 дня)

#### Задача 1.1: Миграция базы данных
```bash
bundle exec rails generate migration CreateMemberRates
```

Содержимое миграции:
```ruby
class CreateMemberRates < ActiveRecord::Migration[7.0]
  def change
    create_table :member_rates do |t|
      t.references :project, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.string :currency, limit: 3, default: 'RUB'
      t.timestamps

      t.index [:project_id, :user_id], unique: true
    end
  end
end
```

#### Задача 1.2: Обновление модели
Добавить в `app/models/project.rb`:
```ruby
has_many :member_rates, dependent: :destroy
has_many :rated_users, through: :member_rates, source: :user
```

Добавить в `app/models/user.rb`:
```ruby
has_many :member_rates, dependent: :destroy
has_many :rated_projects, through: :member_rates, source: :project
```

### Этап 2: Модель MemberRate (0.5 дня)

#### Задача 2.1: Создание модели
```bash
bundle exec rails generate model MemberRate project:references user:references hourly_rate:decimal{10,2} currency:string
```

#### Задача 2.2: Валидации и ассоциации
`app/models/member_rate.rb`:
```ruby
class MemberRate < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, inclusion: { in: %w[RUB EUR USD] }
  validates :project_id, uniqueness: { scope: :user_id }

  CURRENCIES = %w[RUB EUR USD].freeze
end
```

#### Задача 2.3: Базовые тесты модели
`spec/models/member_rate_spec.rb` (минимальные):
```ruby
RSpec.describe MemberRate, type: :model do
  it { should belong_to(:project) }
  it { should belong_to(:user) }
  it { should validate_inclusion_of(:currency).in_array(%w[RUB EUR USD]) }
  it { should validate_numericality_of(:hourly_rate).is_greater_than_or_equal_to(0) }
end
```

### Этап 3: Telegram обработчики (2 дня)

#### Задача 3.1: Базовый обработчик команды
Создать `app/services/telegram/rate_command.rb`:
```ruby
module Telegram
  class RateCommand
    include BaseService

    attr_reader :telegram_user, :message_text

    def initialize(telegram_user, message_text)
      @telegram_user = telegram_user
      @message_text = message_text
    end

    def call
      args = message_text.split(' ')

      case args[1]
      when 'list'
        handle_list(args[2])
      when 'remove'
        handle_remove(args[2], args[3])
      when 'batch'
        handle_batch(args[2])
      when nil
        handle_interactive
      else
        handle_set_rate(args[1], args[2], args[3], args[4])
      end
    end

    private

    def handle_set_rate(project_name, username, amount, currency)
      # Реализация установки ставки
    end

    def handle_interactive
      # Реализация inline интерфейса
    end

    def handle_list(project_name)
      # Реализация просмотра списка
    end

    def handle_remove(project_name, username)
      # Реализация удаления ставки
    end

    def handle_batch(project_name)
      # Реализация пакетного режима
    end
  end
end
```

#### Задача 3.2: Inline обработчик
Создать `app/services/telegram/rate_inline_handler.rb`:
```ruby
module Telegram
  class RateInlineHandler
    include BaseService

    def initialize(callback_query)
      @callback_query = callback_query
    end

    def call
      case callback_query.data
      when /^rate_select_project_(\d+)$/
        show_project_participants($1)
      when /^rate_select_user_(\d+)_(\d+)$/
        ask_for_rate($1, $2)
      when /^rate_set_currency_(\d+)_(\d+)_(.+)$/
        handle_currency_selection($1, $2, $3)
      end
    end

    private

    def show_project_participants(project_id)
      # Показ участников проекта
    end

    def ask_for_rate(project_id, user_id)
      # Запрос суммы ставки
    end

    def handle_currency_selection(project_id, user_id, amount)
      # Обработка выбора валюты
    end
  end
end
```

#### Задача 3.3: Валидатор
Создать `app/services/telegram/rate_validator.rb`:
```ruby
module Telegram
  class RateValidator
    include BaseService

    def initialize(user, project, target_user = nil)
      @user = user
      @project = project
      @target_user = target_user
    end

    def call
      return failure('Проект не найден') unless project
      return failure('Нет доступа') unless can_manage_rates?
      return failure('Участник не найден в проекте') if target_user && !participant?

      success
    end

    private

    def can_manage_rates?
      project.memberships.where(user: user, role: 'owner').exists?
    end

    def participant?
      project.users.include?(target_user)
    end
  end
end
```

### Этап 4: Интеграция с Telegram webhook (1 день)

#### Задача 4.1: Обновление webhook контроллера
В `app/controllers/telegram/webhook_controller.rb` добавить:
```ruby
def handle_rate_command
  result = Telegram::RateCommand.new(telegram_user, message.text).call

  if result.success?
    send_message(result.data)
  else
    send_message("❌ Ошибка: #{result.errors.join(', ')}")
  end
end

def handle_rate_callback
  result = Telegram::RateInlineHandler.new(callback_query).call

  if result.success?
    edit_message(result.data)
  else
    answer_callback_query("❌ Ошибка: #{result.errors.join(', ')}")
  end
end
```

#### Задача 4.2: Роутинг для callback
В роутах добавить обработку callback с префиксом `rate_`.

### Этап 5: Вспомогательные методы (0.5 дня)

#### Задача 5.1: Форматирование ответов
Создать `app/services/telegram/response_formatters/rate_formatter.rb`:
```ruby
module Telegram
  module ResponseFormatters
    class RateFormatter
      def self.rate_set_success(project, user, rate, currency)
        "✅ Ставка успешно установлена!\n" \
        "📊 Проект: #{project.name}\n" \
        "👤 Участник: @#{user.telegram_username}\n" \
        "💰 Сумма: #{rate} #{currency}\n" \
        "📅 Обновлено: #{Time.current.strftime('%d.%m.%Y %H:%M')}"
      end

      def self.project_rates_list(project)
        rates = project.member_rates.includes(:user)

        text = "💰 Ставки проекта \"#{project.name}\":\n\n"

        project.users.each do |user|
          rate = rates.find { |r| r.user_id == user.id }
          rate_text = rate ? "#{rate.hourly_rate} #{rate.currency}" : "Не установлена"
          role = project.memberships.find_by(user: user)&.role == 'owner' ? ' (Владелец)' : ''

          text += "👤 @#{user.telegram_username}#{role}: #{rate_text}\n"
        end

        text
      end
    end
  end
end
```

### Этап 6: Минимальные тесты (1 день)

#### Задача 6.1: Тесты сервисов
`spec/services/telegram/rate_command_spec.rb`:
```ruby
RSpec.describe Telegram::RateCommand, type: :service do
  let(:user) { create(:user) }
  let(:telegram_user) { create(:telegram_user, user: user) }
  let(:project) { create(:project, owner: user) }

  describe '#call' do
    context 'with valid arguments' do
      it 'sets rate for user' do
        target_user = create(:user, telegram_username: 'testuser')
        project.users << target_user

        command = described_class.new(telegram_user, "/rate #{project.name} testuser 50 USD")
        result = command.call

        expect(result.success?).to be true
        rate = MemberRate.find_by(project: project, user: target_user)
        expect(rate.hourly_rate).to eq(50)
        expect(rate.currency).to eq('USD')
      end
    end

    context 'without permissions' do
      it 'returns error' do
        other_user = create(:user)
        telegram_user2 = create(:telegram_user, user: other_user)

        command = described_class.new(telegram_user2, "/rate #{project.name} testuser 50 USD")
        result = command.call

        expect(result.failure?).to be true
        expect(result.errors).to include('Нет доступа')
      end
    end
  end
end
```

#### Задача 6.2: Тесты валидатора
`spec/services/telegram/rate_validator_spec.rb`:
```ruby
RSpec.describe Telegram::RateValidator, type: :service do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:project) { create(:project, owner: owner) }

  before do
    project.users << participant
  end

  it 'validates owner access' do
    validator = described_class.new(owner, project, participant)
    result = validator.call
    expect(result.success?).to be true
  end

  it 'rejects non-owner access' do
    validator = described_class.new(participant, project, owner)
    result = validator.call
    expect(result.failure?).to be true
    expect(result.errors).to include('Нет доступа')
  end
end
```

### Этап 7: Деплой и проверка (0.5 дня)

#### Задача 7.1: Подготовка к деплою
1. Запуск миграций: `bundle exec rails db:migrate`
2. Проверка тестов: `bundle exec rspec spec/`
3. Проверка RuboCop: `bundle exec rubocop`

#### Задача 7.2: Тестирование в development
1. Запуск development сервера: `./bin/dev`
2. Тестирование команды в Telegram с тестовыми данными
3. Проверка всех сценариев из спецификации

## Необходимые файлы

### Новые файлы:
- `db/migrate/*_create_member_rates.rb`
- `app/models/member_rate.rb`
- `app/services/telegram/rate_command.rb`
- `app/services/telegram/rate_inline_handler.rb`
- `app/services/telegram/rate_validator.rb`
- `app/services/telegram/response_formatters/rate_formatter.rb`
- `spec/models/member_rate_spec.rb`
- `spec/services/telegram/rate_command_spec.rb`
- `spec/services/telegram/rate_validator_spec.rb`

### Модифицируемые файлы:
- `app/models/project.rb`
- `app/models/user.rb`
- `app/controllers/telegram/webhook_controller.rb`
- `config/routes.rb`

## Порядок выполнения

1. **День 1 (утро):** Миграция и модели
2. **День 1 (день):** Telegram обработчики
3. **День 2 (утро):** Вебхук и форматирование
4. **День 2 (день):** Тесты и деплой

**Общее время: ~2 дня**

## Критерии готовности

1. ✅ Все миграции применены без ошибок
2. ✅ Команда `/rate` работает в базовом режиме (через аргументы)
3. ✅ Inline интерфейс работает для выбора проекта и участника
4. ✅ Проверка прав доступа работает корректно
5. ✅ Минимальные тесты проходят
6. ✅ Базовые сценарии из спецификации работают в development