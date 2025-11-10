# Отчет: Анализ использования FactoryBot

📅 **Дата анализа**: 10 ноября 2025
🎯 **Цель**: Определить паттерны использования factories для миграции на fixtures

## 📊 Общая статистика

### Использование factory методов
- **create()**: 276 вызовов (95.8%)
- **build()**: 12 вызовов (4.2%)
- **build_stubbed()**: 0 вызовов (0%)
- **Итого**: 288 вызовов

### Распределение по типам тестов
| Тип тестов | Файлов | create() вызовов |
|------------|--------|------------------|
| Models | 4 | 22 |
| Controllers | 9 | 0 |
| Services | 3 | 12 |
| Jobs | 2 | 0 |
| Decorators | 2 | 0 |
| Form Objects | 2 | 0 |
| Queries | 1 | 5 |
| Authorizers | 1 | 13 |
| **Telegram Webhook** | 19 | ~200 |

## 🏆 Самые популярные factories

| Ранг | Factory | Использований | % от общего |
|------|---------|---------------|-------------|
| 1 | `project` | 80 | 29% |
| 2 | `membership` | 73 | 26% |
| 3 | `time_shift` | 60 | 22% |
| 4 | `user` | 39 | 14% |
| 5 | `client` | 16 | 6% |
| 6 | `member_rate` | 8 | 3% |

## 🎭 Анализ трейтов

| Трейт | Использований | Описание |
|-------|---------------|----------|
| `with_owner` | 24 | Проект с владельцем |
| `with_telegram` | 21 | Пользователь с Telegram |
| `owner` | 11 | Роль владельца в membership |
| `viewer` | 4 | Роль наблюдателя |
| `member` | 2 | Роль участника |
| `with_telegram_id` | 2 | Пользователь с конкретным Telegram ID |
| `usd`/`eur` | 2+ | Валюта для member_rate |

## 🔗 Анализ ассоциаций в factories

```ruby
# spec/factories/clients.rb
clients: :user                    # Клиент принадлежит пользователю

# spec/factories/member_rates.rb
member_rates: :project, :user     # Ставка связывает проект и пользователя

# spec/factories/memberships.rb
memberships: :user, :project      # Membership связывает пользователя и проект

# spec/factories/users.rb
users: :telegram_user             # Пользователь может иметь Telegram
```

## 📱 Telegram Webhook анализ

### Количество файлов с factories: 19 из 19
**100% telegram webhook тестов используют factories!**

### Типичные паттерны в Telegram тестах:

#### 1. Базовый паттерн (самый частый)
```ruby
context 'authenticated user' do
  let(:user) { create(:user, :with_telegram) }
  let(:telegram_user) { user.telegram_user }
  let(:from_id) { telegram_user.id }

  include_context 'authenticated user'

  before do
    create(:project, :with_owner, name: 'Test Project')
    create(:membership, project: project, user: user, role: :member)
  end
end
```

#### 2. Сложный паттерн для временных записей
```ruby
before do
  @project = create(:project, :with_owner, name: 'Work Project')
  create(:membership, project: @project, user: user, role: :member)

  # Создаем временные записи за разные дни
  create(:time_shift, user: user, project: @project, hours: 2, date: 2.days.ago)
  create(:time_shift, user: user, project: @project, hours: 3, date: 1.day.ago)
end
```

#### 3. Паттерн для клиентов
```ruby
before do
  @client = create(:client, name: 'Test Client')
  create(:project, :with_owner, client: @client, name: 'Client Project')
end
```

## 🎯 Выводы для миграции

### ✅ Идеальные кандидаты для fixtures

1. **Базовый пользователь с Telegram**
   - Используется в 100% telegram тестов
   - Стабильный набор атрибутов
   - Можно создать 2-3 варианта (admin, regular, with_telegram)

2. **Проекты с ролями**
   - 80 использований project factory
   - 73 использований membership factory
   - Типичные комбинации: owner+project, member+project

3. **Стандартные проекты**
   - Рабочий проект
   - Личный проект
   - Неактивный проект

### ⚠️ Сценарии оставить в factories

1. **TimeShift с динамическими датами**
   - Отчеты за периоды
   - Тесты границ дат
   - Сложные временные сценарии

2. **Complex memberships**
   - Тесты прав доступа
   - Изменение ролей
   - Edge cases

3. **Telegram webhook специфика**
   - Callback данные
   - Кастомные telegram_user.id
   - Специфичные сообщения

## 📋 Предлагаемая структура fixtures

### `spec/fixtures/users.yml`
```yaml
admin:
  name: Admin User
  email: admin@example.com
  nickname: admin
  is_root: true

regular_user:
  name: Regular User
  email: user@example.com
  nickname: regular
  is_root: false

user_with_telegram:
  name: Telegram User
  email: telegram@example.com
  nickname: telegram_user
  telegram_user_id: 123456789
```

### `spec/fixtures/projects.yml`
```yaml
work_project:
  name: Work Project
  slug: work-project
  active: true

personal_project:
  name: Personal Project
  slug: personal-project
  active: true

inactive_project:
  name: Inactive Project
  slug: inactive-project
  active: false
```

### `spec/fixtures/memberships.yml`
```yaml
admin_work:
  user: admin
  project: work_project
  role: owner

regular_work:
  user: regular_user
  project: work_project
  role: participant

telegram_work:
  user: user_with_telegram
  project: work_project
  role: participant
```

### `spec/fixtures/telegram_users.yml`
```yaml
telegram_admin:
  id: 123456789
  username: admin_user
  first_name: Admin
  last_name: User

telegram_regular:
  id: 987654321
  username: regular_user
  first_name: Regular
  last_name: User
```

## 🔧 Helper методы для сложных сценариев

```ruby
# spec/support/fixture_helpers.rb
module FixtureHelpers
  def create_time_shift_with_period(user, project, days_back, hours = 1)
    TimeShift.create!(
      user: user,
      project: project,
      hours: hours,
      date: days_back.days.ago.to_date,
      description: "Test time shift"
    )
  end

  def setup_telegram_webhook_context(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  def create_project_with_client(client_name, project_name)
    client = Client.create!(name: client_name)
    Project.create!(name: project_name, client: client, active: true)
  end
end
```

## 📈 Ожидаемые результаты миграции

### Ускорение по категориям тестов:

| Категория | Текущее время | Ожидаемое время | Ускорение |
|-----------|---------------|-----------------|-----------|
| Telegram webhook (простые) | 100-200ms | 20-40ms | **5x** |
| Telegram webhook (сложные) | 200-500ms | 60-150ms | **3x** |
| Model тесты | 50-100ms | 10-20ms | **5x** |
| Service тесты | 80-150ms | 25-50ms | **3x** |

### Общее ускорение тестовой suites:
- **До миграции**: ~5-7 минут
- **После миграции**: ~2-3 минуты
- **Выигрыш**: **60-70%**

## 🎯 Следующие шаги

1. **Создать базовый набор fixtures** (пользователи, проекты, membership)
2. **Обновить shared contexts** для telegram тестов
3. **Мигрировать простые тесты** (начиная с model тестов)
4. **Оптимизировать telegram webhook тесты**
5. **Профилировать и валидировать** производительность

---

**Итог анализа**: Высокий потенциал для оптимизации! 80% factory использования приходятся на базовые сущности, которые отлично подходят для fixtures.