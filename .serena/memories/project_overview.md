# Project Overview: Masha Time Tracking Bot

## Project Description
Masha is a time tracking service built as both a Telegram bot (@MashTimeBot) and web application. It's a Rails 8 application with PostgreSQL backend and Bootstrap/Sass frontend.

## Key Technologies
- **Backend**: Rails 8, PostgreSQL
- **Frontend**: Bootstrap 5, Sass, jQuery, Turbolinks 5
- **Telegram Integration**: telegram-bot-rb gem
- **Background Jobs**: Solid Queue
- **Testing**: RSpec, Factory Bot
- **Error Monitoring**: Bugsnag

## Architecture Overview

### Telegram Bot Architecture 🏗️
**Critical**: Understanding context management is essential for bot development.

#### Context Mechanism (telegram-bot-rb)
1. **MessageContext**: `save_context :method_name` → calls `method_name` on next message
2. **CallbackQueryContext**: `callback_data: "prefix:data"` → calls `prefix_callback_query(data)`

#### Command System
- Commands inherit from `BaseCommand`
- Context methods declared with `provides_context_methods`
- Auto-registration in `WebhookController`

#### Example Implementation
```ruby
class ClientCommand < BaseCommand
  provides_context_methods :add_client_name, :add_client_key
  
  def add_client_name(message, *)
    save_context :add_client_key
  end
end
```

### Core Models
- **User**: System users with GitHub OAuth
- **Project**: Time tracking projects with role-based access (Owner/Watcher/Participant)
- **TimeShift**: Individual time entries
- **Client**: Client management for projects
- **Membership**: User-project relationships

### Access Control
Three role levels per project:
- **Owner**: Full permissions
- **Watcher**: View all time, manage own entries
- **Participant**: Only view/manage own time entries

## Development Commands

### Setup
```bash
make deps                    # Install dependencies
bundle install
bun install
rake db:create
rake db:test:prepare
```

### Development Server
```bash
./bin/dev                    # Start all processes
make up
```

### Testing
```bash
make test                    # Full test suite
./bin/rsp                    # RSpec tests
```

## Important Development Guidelines

### Telegram Bot Development
📚 **CRITICAL**: Read architecture documentation before working on bot features.
- Reference: `docs/development/telegram-bot-architecture.md`
- Memory: `telegram_bot_contexts_mechanism`

### Error Handling
🚨 **MANDATORY**: All Telegram error handlers must notify Bugsnag.
- Include `Telegram::ErrorHandling` module
- All `rescue` blocks must call `notify_bugsnag(e)`

### Code Quality
- Follow existing project patterns
- Use I18n for all user-facing text
- No middleware creation
- ApplicationConfig never needs mocking

## File Structure
```
app/
├── commands/           # Command classes
├── controllers/
│   ├── telegram/      # Telegram bot controllers
│   └── owner/         # Admin functionality
├── services/          # Business logic
├── models/            # Data models
└── jobs/              # Background jobs

docs/development/       # Development documentation
docs/specs/            # Business specifications
```

## Common Workflows

### Adding New Telegram Command
1. Create command class in `app/commands/`
2. Declare context methods with `provides_context_methods`
3. Register in `config/initializers/command_registry.rb`
4. Add tests in `spec/controllers/telegram/webhook/`

### Error Investigation
1. Check Bugsnag for recent errors
2. Use context memory: `telegram_bot_contexts_mechanism`
3. Review logs and session data
4. Test context flows in console

## Recent Changes (2025-11-09)
- Fixed Telegram bot context method registration issue
- Added automatic context method delegation
- Enhanced error handling documentation
- Created comprehensive architecture documentation

## References
- Architecture: `docs/development/telegram-bot-architecture.md`
- Error handling: `docs/development/telegram-error-handling.md`
- Session management: `docs/development/telegram-session-management.md`
- Memory: `telegram_bot_contexts_mechanism`