# Mashtime.ru Project Overview

## Project Purpose
Masha is a comprehensive time tracking service that operates as both a Telegram bot (@MashTimeBot) and web application. The system allows users to track time spent on projects, manage team memberships, and generate reports through multiple interfaces.

## Core Features
- **Dual Interface**: Web application + Telegram bot for time tracking
- **Project Management**: Create projects with role-based access control (Owner/Watcher/Participant)
- **Time Tracking**: Record time entries with descriptions and hours
- **Team Collaboration**: Invite users, manage roles, and track team time
- **Multi-authentication**: OAuth via GitHub and Telegram integration
- **Reporting**: Generate time summaries and project reports

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8
- **Database**: PostgreSQL with Solid Queue for background jobs
- **Authentication**: Sorcery gem + OAuth (GitHub, Telegram)
- **Authorization**: Authority gem for role-based permissions
- **Background Jobs**: Solid Queue with Redis
- **File Uploads**: CarrierWave + MiniMagick

### Frontend
- **CSS Framework**: Bootstrap 5 with Sass
- **JavaScript**: jQuery + Turbolinks 5
- **Asset Pipeline**: Sprockets with PostCSS/Autoprefixer
- **JavaScript Management**: Importmap Rails
- **UI Components**: Bootstrap Icons, jQuery UI

### Telegram Integration
- **Bot Framework**: telegram-bot gem
- **Real-time Communication**: Webhooks and polling
- **Session Management**: Custom Telegram session handling
- **Command System**: Modular command architecture with base classes

### Development Tools
- **Testing**: RSpec with Factory Bot, Database Cleaner
- **Code Quality**: RuboCop with Rails-specific rules
- **Security**: Brakeman static analysis, Bugsnag error monitoring
- **Documentation**: Custom documentation protocols in `.protocols/`

## Architecture Patterns

### Layered Architecture
```
Controllers (Web/Telegram) 
├── Authorizers (Permissions)
├── Service Objects (Business Logic)
├── Models (Data Layer)
├── Queries (Database Operations)
└── Jobs (Background Processing)
```

### Key Components
- **Models**: User, Project, TimeShift, Membership, Invite with proper associations
- **Authorizers**: Role-based access control with Authority gem
- **Services**: Telegram commands, time tracking logic, project management
- **Controllers**: Standard Rails controllers + Telegram webhook handling
- **Jobs**: Solid Queue for background processing

### Authentication Flow
1. **OAuth**: GitHub integration for web users
2. **Telegram**: Direct bot authentication with user linking
3. **Session Management**: Separate web and Telegram sessions
4. **User Linking**: Automatic attachment of Telegram accounts to existing users

## Database Schema
- **Users**: Core user records with OAuth associations
- **Projects**: Time tracking containers with friendly_id slugs
- **TimeShifts**: Individual time entries with hours and descriptions
- **Memberships**: User-project relationships with role-based permissions
- **Invites**: Project invitation system with email/Telegram integration
- **Authentications**: OAuth provider data (GitHub, Telegram)

## Deployment & Operations
- **Containerization**: Docker with docker-compose
- **Process Management**: Puma web server with Thruster acceleration
- **CI/CD**: GitHub Actions with automated testing and releases
- **Monitoring**: Bugsnag error tracking, health checks
- **Versioning**: Semantic versioning with automated releases

## Development Workflow
```bash
make deps              # Install dependencies (bun, gems)
make up                 # Start development server
make test              # Run full test suite
bundle exec rubocop    # Code linting
```

Development processes:
- Background jobs via `./bin/jobs`
- Telegram bot via polling for development
- CSS compilation with Sass watching
- Guard for automated test execution

## Quality Standards
- **Error Handling**: Mandatory Bugsnag notification for all caught exceptions
- **Security**: Brakeman scanning, input validation, authorization checks
- **Testing**: RSpec with Factory Bot, system tests, email testing
- **Code Style**: RuboCop with 140-character line limit, Rails conventions
- **Documentation**: Business specs in `.protocols/`, technical docs in `docs/`

## Configuration
- **Locales**: Russian locale by default, I18n for all user-facing text
- **Settings**: Centralized configuration via `ApplicationConfig`
- **Environment**: Standard Rails environments with specific configurations
- **Features**: Feature toggles and optional integrations

## Project Scale
- **Target Users**: Small to medium teams requiring time tracking
- **Concurrent Users**: Designed for moderate load with Solid Queue
- **Data Volume**: Optimized for thousands of projects and time entries
- **Geographic Focus**: Russian-language primary with international support