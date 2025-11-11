# Анализ отвалившихся тестов и план исправления

📅 **Дата**: 10 ноября 2025
🎯 **Проблема**: Тесты отвалились после включения transactional fixtures

## 🔍 Основные проблемы

### 1. Конфликт уникальных валидаций User модели

**Проблема**: User имеет uniqueness валидации:
```ruby
validates :nickname, uniqueness: true, allow_blank: true
validates :pivotal_person_id, uniqueness: true, allow_blank: true, numericality: true
validates :email, email: true, uniqueness: true, allow_blank: true
```

**Конфликт**: Fixtures загружают пользователей с этими же уникальными значениями:
```yaml
# spec/fixtures/users.yml
admin:
  nickname: admin          # <-- конфликтует с factory
  email: admin@example.com # <-- конфликтует с factory
  pivotal_person_id: 1     # <-- конфликтует с factory
```

**Результат**: `create(:user, :with_telegram)` падает с `RecordInvalid` из-за уникальных constraint violations.

### 2. Database Cleaner конфигурация

**Проблема**: Transactional fixtures + DatabaseCleaner создают конфликт:
- Transactional fixtures пытаются rollback транзакцию
- DatabaseCleaner пытается clean в той же транзакции

**Результат**: Нестабильное состояние базы данных между тестами.

### 3. Shared context не обновлен

**Проблема**: `spec/support/shared_contexts/telegram_webhook_shared.rb` все еще использует `create(:user)`:
```ruby
let!(:user) { create :user }  # <-- конфликтует с fixtures
```

**Результат**: Даже обновленные тесты используют старый shared context.

## 🎯 Детальный план исправления

### Шаг 1: Исправить конфигурацию DatabaseCleaner (Приоритет: 🔴 Высокий)

**Проблема**: Transactional fixtures несовместимы с DatabaseCleaner для базовых тестов.

**Решение**: Отключить DatabaseCleaner для базовых тестов, оставить только для сложных:
```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  # Убрать DatabaseCleaner для базовых тестов
  config.use_transactional_fixtures = true

  # DatabaseCleaner только для сложных тестов
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, :type => :system) do
    DatabaseCleaner.strategy = :truncation
  end
end
```

### Шаг 2: Обновить shared context (Приоритет: 🔴 Высокий)

**Проблема**: Старый shared context конфликтует с fixtures.

**Решение**: Создать новый shared context с fixtures:
```ruby
# spec/support/shared_contexts/telegram_webhook_fixtures_updated.rb
RSpec.shared_context 'telegram webhook fixtures updated' do
  # Используем fixtures вместо factories
  let(:user) { users(:user_with_telegram) }
  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:from_id) { telegram_user.id }

  shared_context 'authenticated user' do
    before do
      allow(controller).to receive(:current_user) { user }
    end
  end
end
```

### Шаг 3: Мигрировать тесты на fixtures (Приоритет: 🟡 Средний)

**Проблема**: Тесты все еще используют `create()` вместо fixtures.

**Решение**: Постепенная замена:
```ruby
# Было:
let(:user) { create(:user, :with_telegram) }
let!(:project1) { create(:project, name: 'Work Project') }

# Стало:
let(:user) { users(:user_with_telegram) }
let(:work_project) { projects(:work_project) }
```

### Шаг 4: Исправить конфликты в fixtures (Приоритет: 🟡 Средний)

**Проблема**: Fixtures могут конфликтовать между собой при создании новых записей.

**Решение**: Использовать уникальные последовательности в fixtures:
```yaml
# spec/fixtures/users.yml
admin:
  name: Admin User
  nickname: admin_user_12345  # уникальный
  email: admin_12345@example.com  # уникальный
  pivotal_person_id: 1001  # уникальный
```

### Шаг 5: Создать hybrid подход (Приоритет: 🟢 Низкий)

**Проблема**: Некоторые тесты требуют динамического создания данных.

**Решение**: Комбинировать fixtures + factories:
```ruby
context 'dynamic data required' do
  let(:user) { users(:user_with_telegram) }  # fixture

  before do
    # Динамические данные через factories
    @dynamic_project = create(:project, name: 'Dynamic Project')
    create(:membership, project: @dynamic_project, user: user)
  end

  after do
    @dynamic_project&.destroy!
  end
end
```

## 📋 Конкретные исправления

### 1. Обновить spec_helper.rb
```ruby
# Убрать конфликты DatabaseCleaner
config.before(:each) do
  # DatabaseCleaner.start  # <-- УДАЛИТЬ для базовых тестов
end

config.after(:each) do
  # DatabaseCleaner.clean  # <-- УДАЛИТЬ для базовых тестов
end
```

### 2. Создать новый shared context
```ruby
# spec/support/shared_contexts/telegram_webhook_with_fixtures.rb
RSpec.shared_context 'telegram webhook with fixtures' do
  let(:user) { users(:user_with_telegram) }
  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:from_id) { telegram_user.id }

  shared_context 'authenticated user' do
    before do
      allow(controller).to receive(:current_user) { user }
    end
  end
end
```

### 3. Обновить конкретные тесты
```ruby
# spec/controllers/telegram/webhook/projects_command_spec.rb
RSpec.describe Telegram::WebhookController do
  include_context 'telegram webhook with fixtures'  # <-- НОВЫЙ CONTEXT

  context 'authenticated user' do
    # Убрать let(:user) - уже определен в context

    context 'user with projects' do
      let(:work_project) { projects(:work_project) }
      let(:personal_project) { projects(:personal_project) }

      # Убрать create() вызовы, использовать fixtures
    end
  end
end
```

## ⚡ Очередность исправлений

1. **Срочно**: Исправить конфигурацию DatabaseCleaner
2. **Срочно**: Создать новый shared context
3. **Средний**: Мигрировать 1-2 простых теста как proof of concept
4. **Средний**: Исправить конфликты в fixtures при необходимости
5. **Долгий**: Постепенная миграция всех тестов

## 🧪 Тестирование исправлений

### Шаг 1: Базовый тест
```bash
bundle exec rspec spec/fixtures/simple_fixture_test.rb
```

### Шаг 2: Один telegram тест
```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb -e "responds to /projects command without errors"
```

### Шаг 3: Все telegram тесты
```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

### Шаг 4: Замер производительности
```bash
time bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

## 📊 Ожидаемые результаты

После исправлений:
- ✅ Все тесты проходят
- ✅ Ускорение на 30-50% для базовых тестов
- ✅ Стабильная работа transactional fixtures
- ✅ Гибридный подход (fixtures + factories) работает

---

**Статус**: 🔴 Требует срочного исправления конфигурации DatabaseCleaner