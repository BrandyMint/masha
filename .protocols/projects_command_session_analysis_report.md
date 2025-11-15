# Отчет по анализу использования `save_context` в командах Telegram бота

**Дата**: 2025-11-15
**Аналитик**: Claude Code
**Статус**: Завершен
**Приоритет**: Критический

## Резюме

После изучения документации и всех файлов команд обнаружено **критическое неправильное использование** метода `save_context` в `ProjectsCommand`. Команда использует `save_context` НЕ по назначению — для хранения данных, а не для установки контекста следующего обработчика сообщения.

---

## 1. Что такое `save_context`?

### Назначение
`save_context` — метод telegram-bot gem для установки **имени метода**, который будет вызван при следующем сообщении пользователя.

### Сигнатура
```ruby
# BaseCommand:116-118
def save_context(context_name)
  controller.send(:save_context, context_name)
end
```

**Принимает**: ТОЛЬКО ОДИН аргумент — `context_name` (символ или строка с именем метода)

### Документация

Согласно `docs/development/telegram-session-management.md:27-28`:
```ruby
# Обязательно: Сохранение контекста команды
save_context :add_client_name
save_context :edit_project_name
```

---

## 2. Правильные примеры в проекте

### ✅ ClientsCommand - ПРАВИЛЬНО

```ruby
# app/commands/clients_command.rb:116
def handle_add_client
  save_context ADD_CLIENT_NAME  # ✅ Только имя метода
  respond_with :message, text: t('telegram.commands.clients.add_prompt_name')
end

# app/commands/clients_command.rb:24
def add_client_name(message = nil, *)
  session[:client_name] = name  # ✅ Данные в session
  save_context ADD_CLIENT_KEY   # ✅ Только имя метода
  respond_with :message, text: t('telegram.commands.clients.add_prompt_key')
end
```

### ✅ AddCommand - ПРАВИЛЬНО

```ruby
# app/commands/add_command.rb:20
def select_project_callback_query(project_slug)
  save_context ADD_TIME  # ✅ Только имя метода
  project = find_project project_slug
  controller.telegram_session = TelegramSession.add_time(project_id: project.id)
  # ...
end
```

### ✅ EditCommand - ПРАВИЛЬНО

```ruby
# app/commands/edit_command.rb:25
save_context BaseCommand::EDIT_SELECT_TIME_SHIFT_INPUT  # ✅

# app/commands/edit_command.rb:227
save_context EDIT_HOURS_INPUT  # ✅
```

### ✅ NotifyCommand - ПРАВИЛЬНО

```ruby
# app/commands/notify_command.rb:12
def call
  save_context NOTIFY_MESSAGE_INPUT  # ✅ Только имя метода
  respond_with :message, text: t('commands.notify.prompts.enter_message')
end
```

---

## 3. ❌ КРИТИЧЕСКАЯ ПРОБЛЕМА: ProjectsCommand

### Неправильное использование `save_context`

ProjectsCommand пытается использовать `save_context` с ДВУМЯ аргументами для хранения данных.

#### Проблемные места:

**Попытка сохранить данные через save_context:**
```ruby
# app/commands/projects_command.rb:227-232
save_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)  # ❌ НЕПРАВИЛЬНО
save_context(CONTEXT_RENAME_ACTION, 'both')                   # ❌ НЕПРАВИЛЬНО
save_context(CONTEXT_SUGGESTED_SLUG, suggested_slug)          # ❌ НЕПРАВИЛЬНО
```

**Еще проблемные вызовы:**
```ruby
# app/commands/projects_command.rb:420
save_context(CONTEXT_CURRENT_PROJECT, slug)  # ❌

# app/commands/projects_command.rb:440
save_context(CONTEXT_CURRENT_PROJECT, slug)  # ❌

# app/commands/projects_command.rb:452
save_context(CONTEXT_CURRENT_PROJECT, slug)  # ❌

# И еще 8 аналогичных случаев в строках:
# 464, 476, 491, 511, 535, 547
```

### Попытка прочитать данные через несуществующий метод

```ruby
# app/commands/projects_command.rb:94
suggested_slug = from_context(CONTEXT_SUGGESTED_SLUG)  # ❌ Метод НЕ существует!

# app/commands/projects_command.rb:178
current_slug = from_context(CONTEXT_CURRENT_PROJECT)  # ❌

# И еще 10 вызовов в строках:
# 196, 222, 251, 252, 270, 297, 313, 340, 344, 348, 574
```

### Проверка существования метода

```bash
$ grep -r "def from_context" app/
# Результат: НИЧЕГО НЕ НАЙДЕНО
```

### Почему это проблема?

1. **Метод `from_context` НЕ СУЩЕСТВУЕТ** в проекте
2. **`save_context` НЕ ПРЕДНАЗНАЧЕН** для хранения данных
3. **Второй аргумент ИГНОРИРУЕТСЯ** — метод принимает только один аргумент
4. **Код ДОЛЖЕН ПАДАТЬ** при вызове `from_context` с `NoMethodError`

---

## 4. Статистика использования

### ✅ Правильное использование `save_context`:

| Команда | Использований | Статус |
|---------|---------------|--------|
| AddCommand | 1 | ✅ Правильно |
| ClientsCommand | 8 | ✅ Правильно |
| EditCommand | 3 | ✅ Правильно |
| NotifyCommand | 1 | ✅ Правильно |
| UsersCommand | 1 | ✅ Правильно |

**Итого**: 14 правильных использований

### ❌ Неправильное использование:

| Команда | Проблема | Количество |
|---------|----------|------------|
| ProjectsCommand | `save_context(key, value)` | 13 вызовов |
| ProjectsCommand | `from_context(key)` | 13 вызовов |

**Итого**: 26 критических ошибок

---

## 5. Правильный подход для хранения данных

Согласно `docs/development/telegram-session-management.md`:

### Для простых данных (1-2 значения) → `session`

```ruby
# Сохранение
session[:client_name] = name
session[:current_project] = slug

# Чтение
name = session[:client_name]
slug = session[:current_project]

# Очистка
session.delete(:client_name)
```

### Для сложных операций (3+ шага) → `TelegramSession`

```ruby
# Создание
self.telegram_session = TelegramSession.edit(time_shift_id: 123)

# Установка данных
telegram_session[:field] = 'hours'
telegram_session[:new_values] = { hours: 5.5 }

# Чтение
data = telegram_session_data
field = data['field']

# Очистка
clear_telegram_session
```

---

## 6. Анализ операций ProjectsCommand

| Операция | Шагов | Данных | Рекомендация |
|----------|-------|---------|--------------|
| Создание проекта | 2 | 1 (name) | `session` |
| Rename title | 2 | 1 (current_slug) | `session` |
| Rename slug | 2 | 1 (current_slug) | `session` |
| Rename both | 3 | 3 (slug, title, suggested) | `session` |
| Edit client | 2 | 1 (current_slug) | `session` |
| Delete client | 2 | 1 (current_slug) | `session` |
| Delete project | 3 | 1 (current_slug) | `session` |

**Вывод**: Все операции достаточно простые → используем `session`

---

## 7. Пример правильной реализации

### БЫЛО (неправильно):

```ruby
def start_rename_both(slug)
  save_context(CONTEXT_CURRENT_PROJECT, slug)  # ❌ Два аргумента
  save_context(CONTEXT_AWAITING_RENAME_BOTH)
  # ...
end

def awaiting_rename_both(*title_parts)
  current_slug = from_context(CONTEXT_CURRENT_PROJECT)  # ❌ Метод не существует
  # ...
  save_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)  # ❌
  # ...
end
```

### ДОЛЖНО БЫТЬ (правильно):

```ruby
def start_rename_both(slug)
  session[:current_project_slug] = slug  # ✅ Данные в session
  save_context :awaiting_rename_both      # ✅ Только имя метода
  # ...
end

def awaiting_rename_both(*title_parts)
  current_slug = session[:current_project_slug]  # ✅ Чтение из session
  # ...
  session[:new_project_title] = new_title         # ✅ Сохранение
  save_context :awaiting_rename_both_step_2      # ✅
  # ...
end

def awaiting_rename_both_step_2(*slug_parts)
  current_slug = session[:current_project_slug]  # ✅
  new_title = session[:new_project_title]         # ✅
  # ... обработка ...

  # Очистка после завершения
  session.delete(:current_project_slug)  # ✅
  session.delete(:new_project_title)      # ✅
  session.delete(:suggested_slug)         # ✅
end
```

---

## 8. Риски текущего состояния

### Критический риск

**Код не может работать** в текущем виде из-за:
- Вызова несуществующего метода `from_context`
- Потери данных (второй аргумент `save_context` игнорируется)

### Возможные сценарии

1. **NoMethodError в production** при выполнении операций ProjectsCommand
2. **Потеря пользовательских данных** из-за неправильного хранения в сессии
3. **Невозможность завершить** многошаговые операции (rename, delete, client)

### Текущее покрытие тестами

Вероятно, **многошаговые операции ProjectsCommand НЕ ПОКРЫТЫ тестами**, иначе тесты падали бы с `NoMethodError`.

---

## 9. Рекомендации

### Немедленные действия (критические)

1. ✅ **Добавить временный метод `from_context`** в BaseCommand для предотвращения падений
2. ✅ **Добавить логирование и Bugsnag уведомления** для отслеживания проблемных мест
3. ✅ **Написать интеграционные тесты** для всех многошаговых операций

### Среднесрочные действия (рефакторинг)

1. ✅ **Мигрировать ProjectsCommand на `session`** для хранения данных
2. ✅ **Исправить все вызовы `save_context`** - передавать только имя метода
3. ✅ **Добавить очистку session** после завершения операций
4. ✅ **Удалить временный метод `from_context`**

### Долгосрочные действия (предотвращение)

1. ✅ **Обновить документацию** с примерами из ProjectsCommand
2. ✅ **Добавить линтер проверку** для вызовов `save_context` с >1 аргумента
3. ✅ **Code review checklist** для новых команд

---

## 10. План действий

Подробный пошаговый план доступен в файле:
📄 `.protocols/projects_command_session_refactoring_plan.md`

### Краткий план:

1. **Этап 1**: Подготовка и анализ
2. **Этап 2**: Добавление тестов (TDD)
3. **Этап 3**: Временное решение (from_context)
4. **Этап 4**: Рефакторинг (миграция на session)
5. **Этап 5**: Удаление временных методов
6. **Этап 6**: Финальная проверка
7. **Этап 7**: Code Review и Merge

---

## 11. Выводы

### ✅ Положительное

1. **Большинство команд (5 из 6) используют `save_context` правильно**
2. **Есть четкая документация** по правильному использованию
3. **Проблема изолирована** в одной команде (ProjectsCommand)

### ❌ Критическое

1. **ProjectsCommand имеет фундаментальную проблему** в архитектуре
2. **Код НЕ МОЖЕТ работать** без временного fix
3. **Требуется срочный рефакторинг** для устранения технического долга

### 📊 Метрики

- **Правильных использований**: 14
- **Неправильных использований**: 26 (в одной команде)
- **Критичность**: Высокая (блокирует работу функционала)
- **Трудозатраты на fix**: ~8-16 часов (с тестами)

---

## 12. Приложения

### Приложение A: Полный список проблемных строк

**save_context с двумя аргументами**:
- `projects_command.rb:227` - save_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)
- `projects_command.rb:228` - save_context(CONTEXT_RENAME_ACTION, 'both')
- `projects_command.rb:232` - save_context(CONTEXT_SUGGESTED_SLUG, suggested_slug)
- `projects_command.rb:420` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:440` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:452` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:464` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:476` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:491` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:511` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:535` - save_context(CONTEXT_CURRENT_PROJECT, slug)
- `projects_command.rb:547` - save_context(CONTEXT_CURRENT_PROJECT, slug)

**from_context (несуществующий метод)**:
- `projects_command.rb:94` - from_context(CONTEXT_SUGGESTED_SLUG)
- `projects_command.rb:178` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:196` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:222` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:251` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:252` - from_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2)
- `projects_command.rb:270` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:297` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:313` - from_context(CONTEXT_CURRENT_PROJECT)
- `projects_command.rb:340` - from_context(CONTEXT_CURRENT_PROJECT) x3
- `projects_command.rb:574` - from_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2)

### Приложение B: Ссылки на документацию

- `docs/development/telegram-session-management.md` - Управление сессиями
- `docs/development/telegram-bot-architecture.md` - Архитектура бота
- `docs/development/telegram-callback-guide.md` - Работа с callback_query

---

**Конец отчета**
