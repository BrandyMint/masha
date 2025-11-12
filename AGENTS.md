# Repository Guidelines

## Project Structure & Module Organization
Rails code lives in `app/` (controllers, jobs, services) with reusable helpers in `lib/`. Assets compile from `app/assets/stylesheets` into `app/assets/builds`, and static files sit in `public/`. Database changes belong to `db/migrate` with seeds in `db/seeds.rb`. Configuration is centralized in `config/` (routes, Puma, queue, deploy scripts, secrets). Tests mirror the codebase inside `spec/`, while `docs/` and `notes/` track design material.

## Build, Test, and Development Commands
- `make deps` — install Ruby gems and Bun to align runtime versions.
- `bun install && bun run build:css` — install packages and rebuild the Bootstrap/Sass bundle.
- `./bin/dev` — run the Procfile.dev stack (Rails server, Bun watcher, background jobs).
- `make test` / `bundle exec rspec` — prepare the test DB and execute the full RSpec suite, including system specs.
- `bundle exec brakeman --skip-files bin/generate_changelog.rb,bin/generate_claude_changelog.rb` — mirrors `make security` for static analysis.

## Coding Style & Naming Conventions
Use Ruby 3 / Rails 7 defaults: two-space indentation, snake_case file names, CamelCase classes that match their directory path (e.g., `app/services/reports/weekly_summary.rb`). Keep controllers slim; move business logic into POROs under `app/services` or `lib/`. Run `bundle exec rubocop` (with RuboCop Rails) before committing, and rely on the Bun scripts for SCSS builds instead of manual commands.

## Testing Guidelines
RSpec is the single framework; name specs `<feature>_spec.rb` under the matching namespace. After migrations, run `bin/rails db:test:prepare` to sync schema cache. Favor request specs for API controllers, system specs for browser flows, and service/job specs for business rules. Keep fixtures in `spec/fixtures` updated and document external stubs (Telegram, GitHub) inside the example description.

## Commit & Pull Request Guidelines
History favors brief imperative commit summaries (often Russian) such as “БОльше фикстур в тестах”; keep the first line ≤70 characters and add context in the body. Reference issues or TODOs, call out migrations or env changes, and note verification commands (`make test`, `bun run build:css`). PRs should describe the user impact, attach screenshots for UI updates, and mention webhook adjustments for the Telegram bot.

## Security & Configuration Tips
Secrets live in `config/application.yml` and `config/master.key`; never commit regenerated keys—request them from maintainers. When testing Telegram webhooks, use temporary tunnels locally and re-run `rake telegram:bot:set_webhook RAILS_ENV=production` after deployment.

Все ответы на РУССКОМ языке.
