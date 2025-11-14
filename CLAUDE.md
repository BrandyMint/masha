# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Masha is a time tracking service built as both a Telegram bot (@MashTimeBot) and web application. It's a Rails 8 application with PostgreSQL backend and Bootstrap/Sass frontend.

## Термины

Разработчик - пользователь telegram с id указаным в developer_telegram_id

Когда мы говорим "схема базы данных" мы имеем ввиду схему из файла
`db/schema.rb`

Команда в телеграм - метод с восклицательным знаком.

## Telegram Bot Commands

### `/projects` - Управление проектами

Команда для просмотра списка доступных проектов и создания новых проектов.

**Доступ**: Авторизованные пользователи.

**Функциональность**:
1. **Просмотр проектов**: `/projects` - показывает список всех доступных проектов пользователя
2. **Создание проекта напрямую**: `/projects create project-slug` - создает проект с указанным slug
3. **Интерактивное создание**: `/projects create` - запускает процесс создания проекта с запросом slug

**Примеры использования**:
```
/projects
Доступные проекты:
• Work Project
• Personal Project (Client One)

💡 Создать новый проект: /projects create

/projects create my-new-project
✅ Создан проект `my-new-project`

/projects create
📝 Укажите slug (идентификатор) для нового проекта:
awesome-project
✅ Создан проект `awesome-project`
```

**Правила валидации**:
- Slug не может быть пустым
- Slug должен быть уникальным
- Создатель автоматически получает роль `owner`
- Поддерживаются только латинские буквы, цифры и дефисы

### `/notify` - Массовые уведомления (только для разработчиков)

Команда для отправки массовых уведомлений всем пользователям Telegram бота.

**Доступ**: Только для разработчика (проверяется по `developer_telegram_id`).

**Процесс использования**:
1. Разработчик вызывает команду `/notify`
2. Бот запрашивает текст уведомления с возможностью отмены
3. Разработчик вводит сообщение (3-4000 символов)
4. Бот проверяет сообщение и отправляет его всем пользователям
5. Подтверждение с количеством получателей

**Правила валидации**:
- Минимальная длина: 3 символа
- Максимальная длина: 4000 символов
- Отмена возможна через ввод `cancel`
- Пустые сообщения запрещены

**Пример использования**:
```
/notify
📝 Введите текст уведомления (или 'cancel' для отмены):
Плановые технические работы с 15:00 до 16:00 МСК
✅ Уведомление отправлено 150 пользователям
```

### `/clients` - Управление клиентами (компаниями)

Команда для просмотра списка клиентов и управления ними.

**Доступ**: Авторизованные пользователи.

**Функциональность**:
1. **Просмотр клиентов**: `/clients` - показывает список всех клиентов пользователя
2. **Создание клиента**: `/clients add` - запускает процесс создания нового клиента
3. **Просмотр информации**: `/clients show {key}` - показывает подробную информацию о клиенте
4. **Редактирование**: `/clients edit {key}` - позволяет отредактировать название клиента
5. **Удаление**: `/clients delete {key}` - удаляет клиента (с подтверждением)
6. **Проекты клиента**: `/clients projects {key}` - показывает все проекты, связанные с клиентом
7. **Справка**: `/clients help` - показывает справку по команде

**Примеры использования**:
```
/clients
🏢 Ваши клиенты:
• acme-corp - ACME Corporation (3 проекта)
• techstart - TechStart Inc (1 проект)

/clients add
📝 Введите название компании:
Global Solutions LLC
🔑 Введите уникальный ключ:
global-solutions
✅ Клиент 'Global Solutions LLC' (global-solutions) успешно создан!

/clients show acme-corp
🏢 Информация о клиенте:
🔑 Ключ: acme-corp
📝 Название: ACME Corporation
📊 Проектов: 3
```

### `/report` - Универсальные отчеты по времени

Универсальная команда для получения отчетов по потраченному времени с гибкими параметрами периода, фильтрации и форматирования.

**Доступ**: Авторизованные пользователи.

**Функциональность**:

#### Периоды
- **Символьные периоды**: `today`, `yesterday`, `week`, `month`, `quarter`
- **Конкретная дата**: `2025-01-15` (формат YYYY-MM-DD)
- **Диапазон дат**: `2025-01-01:2025-01-31` (формат YYYY-MM-DD:YYYY-MM-DD)
- **По умолчанию**: без параметров показывает отчет за сегодня

#### Фильтры
- **Один проект**: `project:work-project` - фильтр по одному проекту
- **Несколько проектов**: `projects:work,test,admin` - фильтр по нескольким проектам

#### Форматы вывода
- **Summary** (по умолчанию): группировка по проектам с итоговыми часами
- **Detailed**: подробный отчет с описаниями каждой записи времени

#### Интерактивная справка
- `/report help` - показывает главное меню справки с кнопками навигации
- Кнопки разделов: "📅 Периоды", "🔍 Фильтры", "⚙️ Опции", "💡 Примеры"
- Навигация между разделами через inline keyboard

**Примеры использования**:
```
# Базовые команды
/report                           # Отчет за сегодня
/report week                      # Отчет за текущую неделю
/report month                     # Отчет за текущий месяц
/report yesterday                 # Отчет за вчера
/report quarter                   # Отчет за квартал

# С фильтром по проекту
/report week project:work-project # Неделя по проекту work-project
/report month project:test        # Месяц по проекту test

# С несколькими проектами
/report week projects:work,test   # Неделя по проектам work и test

# Детальный формат
/report today detailed            # Сегодня с описаниями
/report week detailed             # Неделя с описаниями

# Конкретные даты
/report 2025-01-15                # Конкретная дата
/report 2025-01-01:2025-01-31     # Диапазон дат

# Комбинированные параметры
/report week project:work detailed                      # Неделя + проект + детально
/report 2025-01-01:2025-01-31 projects:work,test       # Диапазон + проекты
/report month projects:work,test,admin detailed        # Месяц + проекты + детально
```

**Migration Guide - Переход со старых команд**:

Команда `/report` заменяет три устаревшие команды:

| Старая команда | Новая команда | Статус |
|----------------|---------------|---------|
| `/day` | `/report today` | ⚠️ Устарела, но работает |
| `/day project-slug` | `/report today project:project-slug` | ⚠️ Устарела, но работает |
| `/summary day` | `/report today` | ⚠️ Устарела, но работает |
| `/summary week` | `/report week` | ⚠️ Устарела, но работает |
| `/summary month` | `/report month` | ⚠️ Устарела, но работает |
| `/hours` | `/report quarter` | ⚠️ Устарела, но работает |
| `/hours project-slug` | `/report quarter project:project-slug` | ⚠️ Устарела, но работает |

**Примечания**:
- Старые команды продолжают работать и показывают подсказки о новом синтаксисе
- Рекомендуется перейти на `/report` для доступа к новым функциям (диапазоны дат, несколько проектов, детальный формат)
- Для периодов `last_month` и `last_week` в `/summary` пока используйте старую команду
- Справка доступна через `/report help`

## Development Commands

### Setup and Dependencies
```bash
make deps                    # Install dependencies (bun, terminal-notifier, bundle install)
bundle install              # Install Ruby gems
bun install                  # Install JavaScript dependencies
rake db:create               # Create databases
rake db:test:prepare         # Prepare test database
```

### Development Server
```bash
./bin/dev                    # Start development server (uses Procfile.dev)
make up                      # Alias for ./bin/dev
```

The development server runs multiple processes:
- `./bin/jobs` - Background jobs
- `bundle exec rake telegram:bot:poller` - Telegram bot poller
- `bundle exec rails s` - Rails server
- `bun run watch:css` - CSS compilation watcher

### Testing
```bash
make test                    # Run full test suite (test + test:system)
./bin/rails db:test:prepare test test:system  # Full test command
./bin/rsp                      # Run RSpec tests
/bin/guard                        # Run tests with file watching
```

### Linting and Code Quality
```bash
bundle exec rubocop          # Ruby linting
bundle exec brakeman         # Security analysis
```

### CSS/Frontend
```bash
bun run build:css           # Compile and prefix CSS
bun run watch:css           # Watch CSS changes
bun run build:css:compile   # Compile Sass to CSS
bun run build:css:prefix    # Add browser prefixes
```

### Background Jobs and Telegram Bot
```bash
./bin/jobs                  # Start background job processing
bundle exec rake telegram:bot:poller  # Start Telegram bot polling
rake telegram:bot:set_webhook RAILS_ENV=production  # Set webhook for production
```

## Architecture

### Core Domain Models
- **User**: System users with OAuth authentication (GitHub)
- **Project**: Time tracking projects with role-based access
- **TimeShift**: Individual time entries
- **Membership**: User-project relationships with roles (owner/watcher/participant)
- **Invite**: Project invitation system

### Access Control System
Three role levels per project:
- **Owner**: Full permissions (manage time, users, roles)
- **Watcher**: View all time, manage own entries
- **Participant**: Only view/manage own time entries

### Key Application Layers
- **Controllers**: Standard Rails controllers + Owner namespace for admin functionality
- **Authorizers**: Permission logic using Authority gem
- **Decorators**: Presentation logic using Draper gem
- **Form Objects**: Complex form handling
- **Service Objects**: Business logic (app/service/)
- **Jobs**: Background processing with Solid Queue
- **Queries**: Database query objects

### Telegram Bot Integration
- Webhook controller at `telegram/webhook`
- Bot poller for development
- User attachment system for linking Telegram accounts
- OAuth callback handling for Telegram auth
- Mass notification system via `/notify` command (developer only)

### Frontend Architecture
- Bootstrap 5 + Sass
- jQuery with Turbolinks 5
- Importmap for JavaScript modules
- CSS bundling with PostCSS/Autoprefixer

## Key Configuration Files
- `config/routes.rb`: Routes with subdomain admin constraints, Telegram webhook
- `config/application.rb`: Russian locale default, lib autoloading
- `.rubocop.yml`: Ruby style guide (140 char line length, Rails cops enabled)
- `Procfile.dev`: Development process definitions

## Database & Background Jobs
- PostgreSQL with Solid Cache/Queue/Cable
- Redis for caching and job queuing
- Active Job with Solid Queue backend
- Database migrations standard Rails pattern

## Security Features
- OAuth with GitHub integration
- Telegram authentication
- Role-based authorization with Authority
- Bugsnag error monitoring
- Brakeman security scanning

## Testing Stack
- RSpec for unit/integration tests
- Factory Bot for test data
- Guard for automated testing
- Database Cleaner for test isolation
- Email Spec for email testing

## Deployment
- Docker with docker-compose.yaml
- Puma web server
- Thruster for asset acceleration
- GitHub Actions for CI (tests.yml workflow)
- Semver-based releases via Makefile
- Спецификации бизнес-аналитика сохраняются в .protocols/
- План имлементации сохраняется в .protocols/{СПЕЦИФИКАЦИЯ}_plan.md
- Конфиг проекта лежит в ApplicationConfig
- Доступ к ключам конифгурации осуществляпется через метод, типа ApplicationConfig.key
- Мы не пишем тексты в коде, используем локали и I18n
- Спецификации по проекту лежат тут ./docs/specs

# Development Guidelines

📚 **ВАЖНО**: Обязательно к прочтению руководство для разработчиков.

/file:docs/development/README.md

# ВАЖНО

- Чтобы зайти на боевую (production) базу мы используем `psql $PRODUCTION_DATABASE_URI`
- ApplicationConfig НИКОГДА не нужно мокировать, используй те значения которые уже установлены в тестовом конфиге или установи нужные
- Мы не создаем middleware ни при каких условиях
- В provides_context_methods методы указываются ТОЛЬКО через константу
- Мы не добавляем ничего в метод callback_query вместо этого мы разбираемся в
  какую команжу нужно добавить callback_query с нужным префиксом
- @spec/controllers/telegram/webhook/add_command_spec.rb используем как пример
  спека для тестирования поведения конкретной команды
- в тестах контроллера, telegram мы не проверяем значение session чтобы не
  завязываться не реализацию
- при написании тестов мы максимально стараемся не завазываться на реализацию,
  НЕ вызывать и НЕ мокать внутренние метода, проверять только внешнее
  поведение.
- отвечаешь ВСЕГДА на русском
- мы НЕ хардкодим к тестах и rspec-ах тексты, мы используем ссылки на i18n или
  просто проверяем как-то иначе
- мы НЕ тестируем валидацию ключей в моделях
- в тестах телеграм-контроллера мы НЕ используем прямую отправку в контроллер. Так - controller.send(:add_client_name, 'New Client Name') делать ЗАПРЕЩЕНО
- В save_context аргумент передается ТОЛЬКО через константу определенную в
  BaseCommand
- Мы НЕ запускаем ничего через  bin/rsp
- В проекте НЕТ ./bin/rsp
- Запрещено в spec-ах создавать новые записи в базе через .create, .create_with
  и тп. Вместо этого используются fixtures
- В командах (command) ответ и возврат НЕЛЬЗЯ делать так:     

```
respond_with :message, text: t('commands.notify.cancelled')                                                                                                                                                │
return    
```

так как это не вернет собщение.

Ответ и возврат в классах команд нужно делать так:

```
return respond_with :message, text: t('commands.notify.cancelled')
```
