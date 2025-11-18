# План улучшения тестового покрытия Telegram Webhook

## Обзор

Проблема: команда `/rate` не работает из-за множественных двоеточий в callback данных.
Дополнительная проблема: тесты поверхностные и не проверяют реальный функционал.

## Этапы реализации

### Этап 1: Исправление RateCommand callback данных (КРИТИЧЕСКИЙ)

**Цель:** Заменить множественные двоеточия на запятые в callback данных

**Что исправить в `app/commands/rate_command.rb`:**
- `"rate_select_member:#{project.slug}:#{user.id}"` → `"rate_select_member:#{project.slug},#{user.id}"`
- `"rate_remove:#{project.slug}:#{user.id}"` → `"rate_remove:#{project.slug},#{user.id}"`
- `"rate_select_currency:#{project.slug}:#{user.id}:#{currency}"` → `"rate_select_currency:#{project.slug},#{user.id},#{currency}"`

**Что исправить в callback методах:**
- Добавить парсинг параметров через `split(',')`
- Обновить обработку ошибок для неверного формата

**После выполнения:** Запустить `bundle exec rspec spec/controllers/telegram/webhook/rate_command_spec.rb`

---

### Этап 2: Расширение тестов RateCommand (КРИТИЧЕСКИЙ)

**Цель:** Добавить реальные проверки функционала вместо `not_to raise_error`

**Что добавить в `spec/controllers/telegram/webhook/rate_command_spec.rb`:**

1. **Проверки сохранения в базу данных:**
   ```ruby
   it 'saves member rate to database' do
     # Полный workflow + проверка MemberRate.last
   end
   ```

2. **Проверки контента сообщений:**
   ```ruby
   it 'shows proper currency selection menu' do
     expect(response).to include('USD')
     expect(response).to include('EUR')
   end
   ```

3. **Тесты полного workflow:**
   ```ruby
   it 'completes full rate setting workflow' do
     # Выбор проекта → пользователя → валюты → ввод суммы
   end
   ```

4. **Тесты ошибочных ситуаций:**
   ```ruby
   it 'handles unauthorized access gracefully' do
     # Проверить сообщения об ошибках
   end
   ```

**После выполнения:** Запустить `bundle exec rspec spec/controllers/telegram/webhook/rate_command_spec.rb`

---

### Этап 3: Улучшение базовых команд (ВАЖНЫЙ)

**Цель:** Добавить реальные проверки для основных команд

**3.1. Улучшить `add_command_spec.rb`:**
- Проверки сохранения TimeShift
- Проверка текста сообщений
- Тесты с множественными проектами

**3.2. Улучшить `projects_command_spec.rb`:**
- Проверки CRUD операций в базе
- Тесты с разными ролями пользователей

**3.3. Улучшить `clients_command_spec.rb`:**
- Проверки создания/редактирования клиентов
- Связь клиентов с проектами

**3.4. Улучшить `report_command_spec.rb`:**
- Проверки корректности расчетов
- Тесты разных периодов и фильтров

**После выполнения:** Запустить `bundle exec rspec spec/controllers/telegram/webhook/`

---

### Этап 4: Интеграционные тесты (ВАЖНЫЙ)

**Цель:** Создать тесты cross-command workflows

**4.1. Создать `spec/controllers/telegram/webhook/integration_spec.rb`:**
- Создание проекта → установка ставок
- Добавление времени → проверка в отчете
- Создание клиента → привязка к проекту

**4.2. Создать `spec/controllers/telegram/webhook/edge_cases_spec.rb`:**
- Пустые callback данные
- Некорректный формат данных
- Одновременные операции пользователей

**После выполнения:** Запустить `bundle exec rspec spec/controllers/telegram/webhook/integration_spec.rb`

---

### Этап 5: Тесты безопасности и авторизации (ЖЕЛАТЕЛЬНЫЙ)

**Цель:** Добавить тесты прав доступа

**5.1. Создать `spec/controllers/telegram/webhook/authorization_spec.rb`:**
- Блокировка неавторизованных пользователей
- Проверка прав владельца/участника/наблюдателя
- Тесты developer-only команд

**5.2. Улучшить `message_handling_spec.rb`:**
- Обработка некорректных сообщений
- Специальные символы в тексте

**После выполнения:** Запустить `bundle exec rspec spec/controllers/telegram/webhook/authorization_spec.rb`

---

## Команды запуска тестов

После каждого этапа выполнять:

```bash
# Полный цикл тестов Telegram webhook
bundle exec rspec spec/controllers/telegram/webhook/ --format documentation

# Проверка coverage
bundle exec rspec spec/controllers/telegram/webhook/ --format documentation --require simplecov

# Быстрая проверка только измененных файлов
bundle exec rspec spec/controllers/telegram/webhook/rate_command_spec.rb --format documentation
```

## Критерии успеха

- ✅ Все тесты проходят без ошибок
- ✅ Coverage > 80% для telegram webhook
- ✅ Отсутствуют `only: true` в тестах
- ✅ RateCommand работает в production
- ✅ Нет ошибок "Unknown callback_query" в Bugsnag

## Время выполнения

- **Этап 1:** 2-3 часа
- **Этап 2:** 4-6 часов
- **Этап 3:** 6-8 часов
- **Этап 4:** 4-6 часов
- **Этап 5:** 3-4 часа

**Итого:** ~19-27 часов разработки тестов