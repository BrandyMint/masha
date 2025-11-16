# 1. Рефакторинг сессий

Сейчас каждая сессия в виде контекста сохраняется отдельным ключем в session, пример:       
:edit_time_shift_id, :edit_original_values, :edit_field, :edit_new_project_id, :edit_new_hours, :edit_new_description

Это не хорошо, потому что:

1. Пользователь НЕ может находиться одновременно в нескольких сессиях, он делает
   что-то одно.
2. Для очистки сессий нужно знать ВСЕ ключи, а это нарушает принципы SOLID.

Изучи это и предложи 3 плана рефакторинга избавлющих от этих проблем.

* [ ] adduser вынести в /users
* [ ] newprojec вынести в /projects

# 2. Исправление answer_callback_query

**Проблема:** 26 callback-методов в 5 файлах не вызывают `answer_callback_query()`, что приводит к зависанию кнопок на 30 секунд.

**Приоритет:** P0 (критический)
**Срок:** 1-2 дня
**Оценка:** 5-6 часов
**Спецификация:** [`.protocols/callback_query_specification_2025_11_16.md`](.protocols/callback_query_specification_2025_11_16.md)

## 2.1. Этап 1: Подготовка базовых классов (0.5 часа)

* [x] Добавить `safe_answer_callback_query` в BaseCommand
* [x] Добавить `callback_query_context?` в BaseCommand
* [x] Добавить `ensure_callback_answered` в BaseCommand
* [x] Обновить `safe_call` для вызова safety net
* [ ] Создать feature-branch: `feature/answer-callback-query-fix`
* [ ] Запустить тесты для проверки текущего состояния: `make test`

## 2.2. Этап 2: Миграция команд (2.5 часа) ✅ **ГОТОВО**

**Статус:** Все 26 методов успешно мигрированы

### Приоритет 1: report_command.rb (5 методов) ✅ Готово
* [x] `report_periods_callback_query`
* [x] `report_filters_callback_query`
* [x] `report_options_callback_query`
* [x] `report_examples_callback_query`
* [x] `report_main_callback_query`

### Приоритет 2: edit_command.rb (3 метода) ✅ Готово
* [x] `edit_field_callback_query`
* [x] `edit_project_callback_query`
* [x] `edit_confirm_callback_query` (с подтверждением)

### Приоритет 3: users_command.rb (3 метода) ✅ Готово
* [x] `users_add_project_callback_query`
* [x] `users_add_role_callback_query`
* [x] `users_list_project_callback_query`

### Приоритет 4: add_command.rb (1 метод) ✅ Готово
* [x] `select_project_callback_query`

### Приоритет 5: projects_command.rb (14 методов) ✅ Готово
* [x] `projects_create_callback_query`
* [x] `projects_select_callback_query`
* [x] `projects_list_callback_query`
* [x] `projects_rename_callback_query`
* [x] `projects_rename_title_callback_query`
* [x] `projects_rename_slug_callback_query`
* [x] `projects_rename_both_callback_query`
* [x] `projects_rename_use_suggested_callback_query`
* [x] `projects_client_callback_query`
* [x] `projects_client_edit_callback_query`
* [x] `projects_client_delete_callback_query`
* [x] `projects_client_delete_confirm_callback_query`
* [x] `projects_delete_callback_query`
* [x] `projects_delete_confirm_callback_query` (с alert)

**Статистика:**
- Всего методов: 26 / 26 ✅ (100%)
- Всего вызовов: ~50 `safe_answer_callback_query` добавлено
- Файлов изменено: 5 команд + BaseCommand
- Время выполнения: ~2-3 часа

## 2.3. Этап 3: Тестирование (1 час) ✅ **ГОТОВО**

**Результаты:**
- 571 тестов пройдено ✅
- 0 ошибок ✅

* [x] Создать shared example: `spec/support/shared_examples/callback_answered_spec.rb`
* [x] Добавить тесты для 5 callback методов в report_command_spec.rb
* [x] Запустить тесты: `make test`
* [x] Все тесты проходят - callback'и работают корректно

## 2.4. Этап 4: Ручное тестирование (1 час)

* [ ] Запустить локально: `./bin/dev`
* [ ] Протестировать: переименование проекта
* [ ] Протестировать: навигацию по справке
* [ ] Протестировать: подтверждение удаления
* [ ] Проверить, что кнопки не показывают часики > 2 секунд
* [ ] Проверить, что логика не сломана

## 2.5. Этап 5: Завершение (0.5 часа)

* [ ] Обновить README или комментарий в BaseCommand
* [ ] Добавить правило для новых callback методов в TODO
* [ ] Создать PR с описанием изменений
* [ ] Проверить CI: `make test` (все зеленые)
* [ ] Проверить логи на предупреждения

## 2.6. Проверка после деплоя

* [ ] Все 26 методов обновлены
* [ ] Тесты проходят (зеленые)
* [ ] Ручное тестирование подтверждает устранение зависаний
* [ ] В логах отсутствуют предупреждения
* [ ] Пользователи не сообщают о "зависших кнопках"
