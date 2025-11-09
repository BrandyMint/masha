# Essential Commands for Mashtime.ru Development

## Development Setup
```bash
make deps              # Install all dependencies (bun, gems, tools)
make up                # Start development server (./bin/dev)
```

## Testing
```bash
make test              # Run full test suite (test + test:system)
./bin/rails db:test:prepare test test:system  # Full test command
./bin/rsp              # Run RSpec tests only
./bin/guard            # Run tests with file watching
```

## Code Quality
```bash
bundle exec rubocop    # Ruby code linting
bundle exec brakeman   # Security vulnerability scanning
```

## Frontend/CSS
```bash
bun run build:css      # Compile Sass to CSS with prefixes
bun run watch:css      # Watch and auto-compile CSS changes
bun run build:css:compile    # Compile Sass only
bun run build:css:prefix     # Add browser prefixes
```

## Background Services
```bash
./bin/jobs             # Start background job processor
bundle exec rake telegram:bot:poller  # Start Telegram bot for development
```

## Database Operations
```bash
./bin/rails db:create                 # Create databases
./bin/rails db:migrate                 # Run migrations
./bin/rails db:seed                    # Seed data
./bin/rails db:test:prepare           # Prepare test database
```

## Production/Deployment
```bash
make release           # Create patch release
make minor-release     # Create minor release
make patch-release     # Create patch release (default)
rake telegram:bot:set_webhook RAILS_ENV=production  # Set Telegram webhook
```

## Utilities
```bash
make production-psql   # Connect to production database
make clean             # Clean development environment
make list              # List recent GitHub Actions runs
make infra-view        # View infrastructure deployment logs
```

## Docker Development (if needed)
```bash
docker-compose up     # Start all services
docker-compose down   # Stop all services
```

## Quick Development Workflow
1. Start: `make deps && make up`
2. Make changes
3. Test: `make test`
4. Lint: `bundle exec rubocop`
5. Commit (linting will pass)