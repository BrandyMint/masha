# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Masha is a time tracking service built as both a Telegram bot (@MashTimeBot) and web application. It's a Rails 8 application with PostgreSQL backend and Bootstrap/Sass frontend.

## Термины

Разработчик - пользователь telegram с id указаным в developer_telegram_id

Когда мы говорим "схема базы данных" мы имеем ввиду схему из файла
`db/schema.rb`

Команда в телеграм - метод с восклицательным знаком.

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
