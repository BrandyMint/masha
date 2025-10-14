# План имплементации команды /rename

## Этап 1: Подготовка (0.5 дня)

### 1.1. Анализ зависимостей
- [ ] Изучить паттерны валидации в существующих командах
- [ ] Проверить механизм генерации slug в модели Project
- [ ] Изучить как работают права доступа в других командах (adduser)

### 1.2. Обновление конфигурации
- [ ] Добавить команду `rename` в список доступных команд в `webhook_controller.rb:29`
- [ ] Добавить `rename!` в `before_action :require_authenticated` и `require_personal_chat`

## Этап 2: Базовая реализация (1 день)

### 2.1. Создание класса команды
- [ ] Создать файл `app/controllers/telegram/commands/rename_command.rb`
- [ ] Реализовать базовый класс с методом `call`
- [ ] Добавить разбор аргументов (прямое переименование vs выбор из списка)

### 2.2. Реализация прямого переименования
- [ ] Метод `rename_project_directly(project_slug, new_name)`
- [ ] Поиск проекта через `find_project`
- [ ] Проверка прав доступа через `can_rename_project?`
- [ ] Валидация нового названия
- [ ] Обновление проекта и генерация нового slug
- [ ] Отправка сообщения об успехе/ошибке

### 2.3. Реализация выбора из списка
- [ ] Метод `show_projects_selection`
- [ ] Формирование списка доступных проектов (только где пользователь owner)
- [ ] Создание inline keyboard с кнопками проектов
- [ ] Сохранение контекста для ожидания выбора

## Этап 3: Callback обработчики (1 день)

### 3.1. Добавление callback методов
- [ ] Добавить `rename_project_callback_query(project_slug)` в `telegram_callbacks.rb`
- [ ] Добавить `rename_new_name_input(new_name, *)` в `telegram_callbacks.rb`
- [ ] Добавить `rename_confirm_callback_query(action)` для подтверждения

### 3.2. Логика callback обработчиков
- [ ] `rename_project_callback_query`:
  - Поиск и проверка проекта
  - Сохранение проекта в сессию через `TelegramSession`
  - Запрос нового названия у пользователя
- [ ] `rename_new_name_input`:
  - Валидация введенного названия
  - Сохранение в сессию
  - Показ подтверждения с деталями изменений
- [ ] `rename_confirm_callback_query`:
  - Обработка подтверждения/отмены
  - Обновление проекта
  - Очистка сессии

## Этап 4: Вспомогательные методы (0.5 дня)

### 4.1. Методы валидации и проверки
- [ ] `can_rename_project?(user, project)` - проверка прав владельца
- [ ] `validate_project_name(name)` - валидация названия
- [ ] `build_project_selection_keyboard(projects)` - создание клавиатуры
- [ ] `build_rename_confirmation(project, new_name)` - текст подтверждения

### 4.2. Обработка ошибок
- [ ] Реализация обработки различных ошибок:
  - Проект не найден
  - Нет прав доступа
  - Название уже существует
  - Некорректное название
- [ ] Логирование ошибок через Bugsnag

## Этап 5: Сессии и состояние (0.5 дня)

### 5.1. Работа с TelegramSession
- [ ] Добавить методы в `TelegramSession` модель:
  - `self.rename(project_id: project_id)`
  - Изучить существующие паттерны (`add_time`, `edit`, `add_user`)
- [ ] Реализовать сохранение состояния между шагами:
  - Выбранный проект
  - Новое название
  - Текущий шаг процесса

### 5.2. Очистка состояния
- [ ] Реализовать корректную очистку сессии:
  - При успешном переименовании
  - При отмене операции
  - При ошибках

## Этап 6: Тестирование (1 день)

### 6.1. Unit тесты
- [ ] Создать `spec/controllers/telegram/commands/rename_command_spec.rb`
- [ ] Тест прямого переименования
- [ ] Тест выбора из списка
- [ ] Тест валидации аргументов
- [ ] Тест проверки прав доступа

### 6.2. Integration тесты
- [ ] Создать `spec/controllers/telegram/webhook/rename_command_spec.rb`
- [ ] Тест полного сценария через callback'и
- [ ] Тест обработки ошибок
- [ ] Тест очистки сессии

### 6.3. Тесты для callback обработчиков
- [ ] Добавить тесты в `spec/controllers/concerns/telegram_callbacks_spec.rb`
- [ ] Тест `rename_project_callback_query`
- [ ] Тест `rename_new_name_input`
- [ ] Тест `rename_confirm_callback_query`

## Этап 7: Документация и финализация (0.5 дня)

### 7.1. Обновление документации
- [ ] Добавить команду в `/help` (в `help_command.rb`)
- [ ] Обновить `README.md` или документацию Telegram команд
- [ ] Добавить примеры использования в документацию

### 7.2. Code review и оптимизация
- [ ] Проверка соответствия Ruby style guide
- [ ] Запуск RuboCop и исправление замечаний
- [ ] Оптимизация запросов к БД
- [ ] Проверка на потенциальные N+1 проблемы

## Этап 8: Деплой и мониторинг (0.5 дня)

### 8.1. Подготовка к деплою
- [ ] Создать миграцию при необходимости (если меняются модели)
- [ ] Обновить CHANGELOG.md
- [ ] Создать tag новой версии

### 8.2. Тестирование в production-like среде
- [ ] Тест на staging сервере
- [ ] Проверка работы с реальными Telegram пользователями
- [ ] Мониторинг логов на предмет ошибок

## Детальные технические решения

### Структура файлов для создания:

```
app/controllers/telegram/commands/
├── rename_command.rb (новый)

spec/controllers/telegram/commands/
├── rename_command_spec.rb (новый)

spec/controllers/telegram/webhook/
├── rename_command_spec.rb (новый)
```

### Модифицируемые файлы:

```
app/controllers/telegram/webhook_controller.rb
app/controllers/concerns/telegram_callbacks.rb
app/controllers/telegram/commands/help_command.rb
spec/controllers/concerns/telegram_callbacks_spec.rb
```

### Порядок вызовов при прямом переименовании:

1. `rename!('project-slug', 'New Name')` → webhook_controller
2. `RenameCommand#call` → rename_command.rb
3. `rename_project_directly` → rename_command.rb
4. `can_rename_project?` → rename_command.rb
5. `project.update!` → project.rb
6. Ответ пользователю → rename_command.rb

### Порядок вызовов при выборе из списка:

1. `rename!()` → webhook_controller
2. `RenameCommand#call` → rename_command.rb
3. `show_projects_selection` → rename_command.rb
4. Пользователь нажимает кнопку → telegram
5. `rename_project_callback_query` → telegram_callbacks.rb
6. `save_context :rename_new_name_input` → telegram_callbacks.rb
7. Пользователь вводит название → telegram
8. `rename_new_name_input` → telegram_callbacks.rb
9. `save_context :rename_confirm_callback_query` → telegram_callbacks.rb
10. Пользователь подтверждает → telegram
11. `rename_confirm_callback_query` → telegram_callbacks.rb
12. `project.update!` → project.rb
13. Очистка сессии → telegram_callbacks.rb

## Критерии готовности

- [ ] Все unit тесты проходят
- [ ] Все integration тесты проходят
- [ ] RuboCop не находит ошибок
- [ ] Brakeman не находит уязвимостей
- [ ] Команда работает для обоих сценариев
- [ ] Правильно обрабатываются все ошибки
- [ ] Сессии корректно очищаются
- [ ] Документация обновлена
- [ ] Тестирование на staging успешно

## Риски и митигация

**Риск 1:** Проблемы с генерацией slug
*Митигация:* Изучить существующие тесты для Project model и friendly_id

**Риск 2:** Сложности с callback обработчиками
*Митигация:* Следовать паттернам из edit_command и adduser_command

**Риск 3:** Проблемы с сессиями
*Митигация:* Использовать проверенные паттерны из TelegramSession

**Риск 4:** Проблемы с правами доступа
*Митигация:* Скопировать логику проверки из adduser_command

## Оценка временных затрат

- **Этап 1:** 0.5 дня
- **Этап 2:** 1 день
- **Этап 3:** 1 день
- **Этап 4:** 0.5 дня
- **Этап 5:** 0.5 дня
- **Этап 6:** 1 день
- **Этап 7:** 0.5 дня
- **Этап 8:** 0.5 дня

**Итого:** 5.5 дней (~1 рабочая неделя)

## Зависимости от других разработчиков

- Нет-blocking зависимостей
- Можно работать параллельно с другими задачами
- Не требует миграций схемы БД