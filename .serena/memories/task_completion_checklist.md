# Task Completion Checklist

## When a Task is Complete

### Code Quality Checklist
- [ ] **Testing**: `make test` passes (unit + integration + system tests)
- [ ] **Linting**: `bundle exec rubocop` passes with no offenses
- [ ] **Security**: `bundle exec brakeman` shows no new vulnerabilities
- [ ] **Functionality**: Manual testing confirms feature works as expected

### Code Review Checklist
- [ ] **Architecture**: Follows existing patterns and conventions
- [ ] **Error Handling**: All `rescue` blocks in Telegram controllers include `notify_bugsnag(e)`
- [ ] **Authorization**: Authority gem checks present for protected actions
- [ ] **Validation**: Models have proper validations with Russian error messages
- [ ] **Database**: Migrations are reversible and follow naming conventions
- [ ] **Frontend**: CSS compiles, JavaScript works with Turbolinks
- [ ] **Internationalization**: All user-facing text uses I18n with Russian locale

### Documentation Checklist
- [ ] **Code Comments**: Russian comments for domain-specific logic
- [ ] **API Documentation**: Models and service objects are documented
- [ ] **Business Logic**: Complex business rules explained in comments
- [ ] **Protocol Documentation**: Business specs updated in `.protocols/` if needed

### Telegram Bot Specific
- [ ] **Error Handling**: All commands handle exceptions with Bugsnag notification
- [ ] **User Experience**: Error messages are user-friendly and in Russian
- [ ] **Session Management**: Telegram sessions properly managed
- [ ] **Command Patterns**: Follow existing command structure

### Database Checklist
- [ ] **Migrations**: Follow naming conventions and are reversible
- [ ] **Indexes**: Proper indexes added for performance
- [ ] **Foreign Keys**: Data integrity maintained
- [ ] **Schema**: `db/schema.rb` updated and committed

### Performance Checklist
- [ ] **N+1 Queries**: Avoided with proper eager loading
- [ ] **Background Jobs**: Heavy operations moved to Solid Queue
- [ ] **Caching**: Appropriate caching strategies implemented
- [ ] **Database**: Queries optimized with proper indexes

### Security Checklist
- [ ] **Input Validation**: All user inputs sanitized
- [ ] **Authorization**: Authority gem properly configured
- [ ] **Authentication**: OAuth flows secure and tested
- [ ] **CSRF Protection**: Rails CSRF protection enabled
- [ ] **SQL Injection**: ActiveRecord properly used

### Deployment Checklist
- [ ] **Environment Variables**: All required env vars documented
- [ ] **Dependencies**: Gemfile and package.json up to date
- [ ] **Migration Safety**: Production migrations safe and reversible
- [ ] **Assets**: CSS properly compiled and optimized

## Final Commands to Run
```bash
# 1. Check code quality
bundle exec rubocop

# 2. Run security scan
bundle exec brakeman

# 3. Run tests
make test

# 4. Compile CSS (if frontend changes)
bun run build:css

# 5. Prepare database (if migrations)
./bin/rails db:migrate
./bin/rails db:test:prepare
```

## Commit Standards
- Use descriptive commit messages in Russian/English
- Include issue/PR references when applicable
- Keep commits atomic and focused
- Ensure CI passes before pushing

## Monitoring After Deployment
- Monitor Bugsnag for new errors
- Check Solid Queue dashboard for job failures
- Monitor database performance
- Verify Telegram bot functionality