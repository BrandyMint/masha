# ProjectsCommand Refactoring Inventory

**Дата создания**: 2025-11-15
**Текущая ветка**: fix/projects-3
**Целевая ветка для рефакторинга**: refactor/projects-command-session-management (конфликт worktree)

## 1. Проблемные вызовы from_context

**Всего найдено**: 13 вызовов

### Детальный список:

| Строка | Контекст | Проблема |
|--------|----------|----------|
| 94 | `projects_rename_use_suggested_callback_query` | ✅ ПРАВИЛЬНО: Читает сохраненное значение |
| 178 | `awaiting_rename_title` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 196 | `awaiting_rename_slug` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 222 | `awaiting_rename_both` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 251 | `awaiting_rename_both_step_2` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 252 | `awaiting_rename_both_step_2` | ✅ ПРАВИЛЬНО: Читает значение сохраненное в шаге 1 |
| 270 | `awaiting_client_name` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 297 | `awaiting_client_delete_confirm` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 313 | `awaiting_delete_confirm` | ⚠️ ПРОБЛЕМА: Читает без предварительного сохранения в callback |
| 340 | `handle_cancel_input :rename_*` | ⚠️ ПРОБЛЕМА: Читает в обработке отмены |
| 344 | `handle_cancel_input :client_*` | ⚠️ ПРОБЛЕМА: Читает в обработке отмены |
| 348 | `handle_cancel_input :delete` | ⚠️ ПРОБЛЕМА: Читает в обработке отмены |
| 574 | `use_suggested_slug` | ✅ ПРАВИЛЬНО: Читает сохраненное значение из шага 1 |

### Анализ проблем:

**Проблемных вызовов**: 10 из 13 (77%)

**Паттерн проблемы**:
```ruby
# НЕПРАВИЛЬНО: context method читает slug без сохранения в callback_query
def awaiting_rename_title(...)
  current_slug = from_context(CONTEXT_CURRENT_PROJECT)  # ❌ Откуда slug?
  project = current_user.projects.find_by(slug: current_slug)
  # ...
end

# Callback который должен был сохранить:
def projects_rename_title_callback_query(data = nil)
  start_rename_title(data)  # Передает slug через параметр, не сохраняет в context
end

# start_rename_title сохраняет только AWAITING флаг:
def start_rename_title(slug)
  save_context_with_value(CONTEXT_CURRENT_PROJECT, slug)  # ✅ Сохраняет
  save_context(CONTEXT_AWAITING_RENAME_TITLE)            # ✅ Устанавливает флаг
  # ...
end
```

**Правильные примеры**:
```ruby
# ✅ ПРАВИЛЬНО: Двухшаговый процесс с сохранением промежуточного значения
def awaiting_rename_both(*title_parts)
  new_title = title_parts.join(' ').strip
  # Сохраняем для следующего шага
  save_context_with_value(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)
  # ...
end

def awaiting_rename_both_step_2(*slug_parts)
  new_title = from_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2)  # ✅ Читает сохраненное
  # ...
end
```

## 2. Проблемные вызовы save_context_with_value

**Всего найдено**: 12 вызовов

### Детальный список:

| Строка | Метод | Что сохраняет | Статус |
|--------|-------|---------------|--------|
| 227 | `awaiting_rename_both` | `CONTEXT_AWAITING_RENAME_BOTH_STEP_2` с новым названием | ✅ ПРАВИЛЬНО |
| 228 | `awaiting_rename_both` | `CONTEXT_RENAME_ACTION` = 'both' | ⚠️ НЕИСПОЛЬЗУЕТСЯ |
| 232 | `awaiting_rename_both` | `CONTEXT_SUGGESTED_SLUG` | ✅ ПРАВИЛЬНО |
| 420 | `show_rename_menu` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 440 | `start_rename_title` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 452 | `start_rename_slug` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 464 | `start_rename_both` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 476 | `start_client_edit` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 491 | `confirm_client_deletion` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 511 | `confirm_project_deletion` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 535 | `request_deletion_confirmation` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |
| 547 | `show_client_menu` | `CONTEXT_CURRENT_PROJECT` с slug | ✅ ПРАВИЛЬНО |

### Анализ:

**Неиспользуемые сохранения**: 1 (строка 228 - `CONTEXT_RENAME_ACTION`)

**Правильные использования**: 11 из 12 (92%)

## 3. Текущее покрытие тестами

### Статус запуска тестов:
```
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

**Результат**: 23 examples, 7 failures (70% pass rate)

### Проваленные тесты:

1. **Client management - removes client** (строка 369)
   - Проблема: `project.reload.client` не меняется на `nil`
   - Причина: Контекст не передается между callback и context method

2. **Client management - sets client** (строка 346)
   - Проблема: `project.reload.client&.name` не меняется на 'ACME Corporation'
   - Причина: Контекст не передается между callback и context method

3. **Rename slug only** (строка 235)
   - Проблема: `project.reload.slug` не меняется
   - Причина: Контекст не передается между callback и context method

4. **Rename both - workflow** (строка 264)
   - Проблема: `project.reload.name` и `project.slug` не меняются
   - Причина: Многошаговый процесс с контекстом не работает

5. **Rename both - suggested slug button** (строка 292)
   - Проблема: `suggested_button` is `nil`
   - Причина: Кнопка не создается или не передается в response

6. **Delete project - cancel on wrong name** (строка 451)
   - Проблема: Missing fixture `telegram_test_project`
   - Причина: Отсутствующая фикстура (не связано с контекстом)

7. **Delete project - deletes through workflow** (строка 415)
   - Проблема: Missing fixture `telegram_test_project`
   - Причина: Отсутствующая фикстура (не связано с контекстом)

### Непокрытые многошаговые операции:

1. ✅ **Project creation** - ПОКРЫТО (16 passed tests)
   - Прямое создание: `/projects create slug`
   - Интерактивное: `/projects create` → имя проекта

2. ⚠️ **Rename title only** - ЧАСТИЧНО (1 passed, но проблемы с контекстом)
   - Callback → ввод нового названия → успех

3. ❌ **Rename slug only** - НЕ РАБОТАЕТ (1 failed)
   - Callback → ввод нового slug → **FAILED**

4. ❌ **Rename both** - НЕ РАБОТАЕТ (2 failed)
   - Callback → ввод названия → ввод slug → **FAILED**
   - Callback → ввод названия → кнопка "Use suggested" → **FAILED**

5. ❌ **Client management** - НЕ РАБОТАЕТ (2 failed)
   - Установка клиента: Callback → ввод имени → **FAILED**
   - Удаление клиента: Callback → подтверждение → **FAILED**

6. ❌ **Delete project** - НЕ РАБОТАЕТ (2 failed из-за фикстур)
   - Удаление: Callback → подтверждение 1 → ввод имени → **FAILED**
   - Отмена: Callback → подтверждение 1 → неправильное имя → **FAILED**

## 4. Корневая причина проблем

### Архитектурная проблема:

**Callback query методы** передают `slug` через параметр `data`, но **не сохраняют** его в session context:

```ruby
# ❌ ПРОБЛЕМА: slug передается через data, но не сохраняется
def projects_rename_slug_callback_query(data = nil)
  start_rename_slug(data)  # data = "project-slug"
end

def start_rename_slug(slug)
  # Сохраняет slug в контекст ✅
  save_context_with_value(CONTEXT_CURRENT_PROJECT, slug)
  # Устанавливает флаг awaiting ✅
  save_context(CONTEXT_AWAITING_RENAME_SLUG)
  # Отправляет сообщение пользователю ✅
end

# ❌ НО: Следующий запрос пользователя создает НОВУЮ СЕССИЮ
def awaiting_rename_slug(*slug_parts)
  current_slug = from_context(CONTEXT_CURRENT_PROJECT)  # ❌ NIL - контекст потерян!
  # ...
end
```

### Механизм проблемы:

1. **Callback query** вызывается с `data` (например, "project-slug")
2. Callback вызывает `start_rename_*(data)`, который:
   - Сохраняет `data` в контекст через `save_context_with_value`
   - Устанавливает awaiting флаг через `save_context`
3. **НО**: Контекст сохраняется в ТЕКУЩЕЙ сессии Telegram
4. Когда пользователь отправляет следующее сообщение:
   - Создается **НОВЫЙ запрос** с **НОВОЙ сессией**
   - `from_context` возвращает `nil`, так как контекст не передался
5. Context method (`awaiting_rename_*`) получает `nil` вместо slug

### Почему некоторые тесты проходят:

Тесты **project creation** проходят, потому что они:
1. Не используют промежуточное сохранение `CONTEXT_CURRENT_PROJECT`
2. Работают в рамках ОДНОЙ сессии (callback → context method)
3. Используют только `CONTEXT_AWAITING_PROJECT_NAME` флаг

### Решение:

Использовать правильный паттерн из `AddCommand`:
- Callback query должен сохранять `slug` НАПРЯМУЮ в session через механизм сессий
- Context method должен читать из ПРАВИЛЬНОГО места (session, а не временного контекста)

## 5. Статистика

### Общая картина:

- **Всего методов callback_query**: 15
- **Методов context**: 8
- **Проблемных from_context**: 10 из 13 (77%)
- **Правильных save_context_with_value**: 11 из 12 (92%)
- **Тестов пройдено**: 16 из 23 (70%)
- **Тестов провалено**: 7 из 23 (30%)
  - Связано с контекстом: 5 (71%)
  - Связано с фикстурами: 2 (29%)

### Приоритеты для рефакторинга:

1. **HIGH**: Исправить механизм передачи контекста между callback и context methods (5 failed tests)
2. **MEDIUM**: Добавить отсутствующие фикстуры для delete tests (2 failed tests)
3. **LOW**: Удалить неиспользуемое сохранение `CONTEXT_RENAME_ACTION` (1 строка)

## 6. Следующие шаги (Этап 2)

1. Изучить как `AddCommand` решает эту проблему
2. Создать аналогичный паттерн для `ProjectsCommand`
3. Написать failing tests для всех проблемных сценариев
4. Реализовать исправления
5. Проверить что все тесты проходят

---

**Файл создан автоматически в рамках Этапа 1 рефакторинга ProjectsCommand**
