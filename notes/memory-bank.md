# Memory Bank

## Проект Masha

### Основная информация
- **Название**: Masha - сервис отслеживания времени
- **Telegram бот**: @MashTimeBot
- **Технологии**: Rails 8, PostgreSQL, Bootstrap 5, Sass

### Архитектура
- **Основные модели**: User, Project, TimeShift, Membership, Invite
- **Роли**: Owner/Watcher/Participant
- **Аутентификация**: OAuth с GitHub
- **Фоновые задачи**: Solid Queue

### Команды разработки
```bash
./bin/dev                    # Запуск dev сервера
make test                    # Запуск тестов
bundle exec rubocop          # Линтинг
```

### Важные ссылки
- Telegram webhook: `telegram/webhook`
- Конфиг: `config/routes.rb`
- Схема БД: `db/schema.rb`

---
*Создано: 2025-10-09*