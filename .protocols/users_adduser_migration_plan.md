# План переноса команды `/adduser` в `/users add`

## Обзор

Необходимо перенести функционал команды `/adduser` в виде подкоманды `/users add`, сохранив обратную совместимость.

## Текущий анализ

### Команда `/adduser`
- **Назначение:** Добавление пользователя в проект с ролями owner/viewer/member
- **Доступ:** Только владельцы проектов
- **Формат:** `/adduser {project_slug} {username} [role]`
- **Файл:** `app/commands/adduser_command.rb`

### Команда `/users`
- **Назначение:** Показ всех пользователей системы (только для разработчика)
- **Доступ:** Только разработчик
- **Файл:** `app/commands/users_command.rb`

### Зависимости
- `TelegramProjectManager` - основная бизнес-логика
- `TelegramSession` - управление состоянием сессий
- Контекст methods: `adduser_project`, `adduser_username_input`
- Callback handlers: `adduser_project_callback_query`, `adduser_role_callback_query`

## Предлагаемое решение

### 1. Изменить архитектуру команды `/users`
Разделить функционал на подкоманды:
- `/users` (без параметров) - список пользователей текущего проекта
- `/users all` - список всех пользователей системы (только для разработчика)
- `/users add {project_slug} {username} [role]` - добавить пользователя в проект
- `/users remove {project_slug} {username}` - удалить пользователя из проекта
- `/users help` - справка по подкомандам

### 2. Миграция функционала `/adduser`

#### Новые контекст методы в `UsersCommand`
```ruby
provides_context_methods :users_add_project, :users_add_username_input
```

#### Новые callback handlers
```ruby
def users_add_project_callback_query(project_slug)
def users_add_username_input(username, *)
def users_add_role_callback_query(role)
def users_list_project_callback_query(project_slug)
```

#### Новые методы в `TelegramSession`
```ruby
def self.users_add_user(project_slug:)
```

### 3. Обеспечение обратной совместимости
- Оставить `AdduserCommand` с предупреждением об устаревании
- Перенаправлять `/adduser` на новый функционал `/users add`
- Обновить help тексты

### 4. Тестирование
- Адаптировать существующие тесты `adduser_command_spec.rb`
- Добавить новые тесты для `users_command_spec.rb`
- Проверить все сценарии использования

## Технические изменения по файлам

### 1. `app/commands/users_command.rb`
- Добавить роутинг подкоманд в методе `call(action = nil, *args)`
- Добавить context methods: `users_add_project`, `users_add_username_input`
- Добавить callback handlers: `users_*_callback_query`
- Добавить приватные методы:
  - `show_project_users`
  - `show_all_users`
  - `users_add(*args)`
  - `users_remove(*args)`
  - `show_users_help`
  - `show_users_for_project(project)`
  - `show_manageable_projects_for_add`
  - `add_user_to_project(project_slug, username, role)`

### 2. `app/models/telegram_session.rb`
- Добавить `users_add_user` в `VALID_TYPES`
- Добавить фабричный метод `self.users_add_user(project_slug:)`

### 3. `app/commands/help_command.rb`
- Обновить текст команды `/adduser` на `/users add`
- Добавить описание новых подкоманд `/users`

### 4. `app/commands/adduser_command.rb`
- Добавить deprecation warning
- Перенаправить на `UsersCommand` через `UsersCommand.new(current_user, controller: controller).call('add', *args)`

### 5. Тесты
- `spec/controllers/telegram/webhook/adduser_command_spec.rb` - адаптировать
- `spec/controllers/telegram/webhook/users_command_spec.rb` - создать новый
- Обновить все callback data строки с `adduser_*` на `users_add_*`

## Стратегия реализации

### Фаза 1: Подготовка
1. Создать новую структуру `UsersCommand` с подкомандами
2. Добавить новые методы в `TelegramSession`
3. Тестировать новую функциональность параллельно со старой

### Фаза 2: Обратная совместимость
1. Обновить `AdduserCommand` для использования новой логики
2. Добавить deprecation предупреждения
3. Обновить help тексты

### Фаза 3: Тестирование
1. Адаптировать существующие тесты
2. Создать новые тесты для `/users` подкоманд
3. Обеспечить покрытие всех сценариев

### Фаза 4: Завершение
1. Обновить документацию
2. Запланировать будущее удаление `/adduser`
3. Создать миграционный гайд для пользователей

## Ожидаемый результат

- ✅ Единая точка управления пользователями через `/users`
- ✅ Сохранение функционала и обратной совместимости
- ✅ Более логичная структура команд
- ✅ Расширенные возможности просмотра пользователей проектов
- ✅ Готовность к будущим улучшениям (удаление, редактирование ролей)