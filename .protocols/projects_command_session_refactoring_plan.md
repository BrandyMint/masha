# План рефакторинга ProjectsCommand - Исправление управления сессиями

**Дата создания**: 2025-11-15
**Статус**: Запланировано
**Приоритет**: Критический
**Тип**: Технический долг / Исправление критической ошибки

## Проблема

ProjectsCommand содержит критическую ошибку в использовании механизмов управления сессиями telegram-bot gem:

1. **Использует несуществующий метод `from_context()`** - вызывается 13 раз, но метод не определен нигде в проекте
2. **Неправильно использует `save_context()`** - вызывает с ДВУМЯ аргументами (имя + значение), хотя метод принимает только один аргумент (имя следующего обработчика)
3. **Хранит данные в неправильном месте** - пытается использовать `save_context` как хранилище данных вместо `session`

## Анализ использования в проекте

### ✅ Правильное использование (остальные команды)
- **AddCommand**: 1 использование - правильно
- **ClientsCommand**: 8 использований - правильно
- **EditCommand**: 3 использования - правильно
- **NotifyCommand**: 1 использование - правильно
- **UsersCommand**: 1 использование - правильно

### ❌ Неправильное использование (ProjectsCommand)
- 13 вызовов `save_context(key, value)` с ДВУМЯ аргументами
- 13 вызовов несуществующего `from_context(key)`
- Код НЕ МОЖЕТ работать в текущем виде

## Цель рефакторинга

Устранить неправильное использование `save_context` и полностью удалить все вызовы несуществующего метода `from_context`, заменив их на правильные подходы работы с сессиями согласно документации `docs/development/telegram-session-management.md`.

---

## Этап 1: Подготовка и анализ

### 1.1 Инвентаризация проблемных мест

**Задача**: Составить полный список всех проблемных вызовов

```bash
# Найти все вызовы save_context с двумя аргументами
grep -n "save_context.*,.*)" app/commands/projects_command.rb

# Найти все вызовы from_context
grep -n "from_context" app/commands/projects_command.rb
```

**Проблемные строки**:
- Строка 94: `suggested_slug = from_context(CONTEXT_SUGGESTED_SLUG)`
- Строка 178: `current_slug = from_context(CONTEXT_CURRENT_PROJECT)`
- Строка 196: `current_slug = from_context(CONTEXT_CURRENT_PROJECT)`
- Строка 222: `current_slug = from_context(CONTEXT_CURRENT_PROJECT)`
- Строка 227: `save_context(CONTEXT_AWAITING_RENAME_BOTH_STEP_2, new_title)`
- Строка 228: `save_context(CONTEXT_RENAME_ACTION, 'both')`
- Строка 232: `save_context(CONTEXT_SUGGESTED_SLUG, suggested_slug)`
- Строка 251-252: `current_slug = from_context(...)`, `new_title = from_context(...)`
- И еще ~15 аналогичных случаев

### 1.2 Анализ текущего покрытия тестами

```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

**Действия**:
- Проверить какие сценарии покрыты
- Определить какие многошаговые операции НЕ покрыты
- Зафиксировать текущее состояние

### 1.3 Создать feature branch

```bash
git checkout -b refactor/projects-command-session-management
```

---

## Этап 2: Добавление тестов (TDD подход)

### 2.1 Написать failing tests для всех многошаговых операций

**Цель**: Покрыть тестами все сценарии ДО начала рефакторинга

**Файл**: `spec/controllers/telegram/webhook/projects_command_spec.rb`

#### 2.1.1 Тесты для создания проекта

```ruby
context 'create project workflow' do
  it 'creates project through interactive workflow' do
    # 1. Пользователь нажимает кнопку "Создать проект"
    response = dispatch(callback_query: { data: 'projects_create:' })
    expect(response).not_to be_nil

    # 2. Пользователь вводит название
    expect do
      dispatch_message('My New Project')
    end.to change(Project, :count).by(1)

    # 3. Проверяем что проект создан с правильными данными
    project = Project.last
    expect(project.name).to eq('My New Project')
    expect(project.memberships.owners.where(user: user).exists?).to be true
  end
end
```

#### 2.1.2 Тесты для переименования - только title

```ruby
context 'rename project title only' do
  let(:project) { projects(:work_project) }

  it 'renames project title through workflow' do
    dispatch(callback_query: { data: "projects_rename:#{project.slug}" })
    dispatch(callback_query: { data: "projects_rename_title:#{project.slug}" })

    expect do
      dispatch_message('New Project Title')
    end.to change { project.reload.name }.to('New Project Title')

    expect(project.slug).to eq(project.slug) # slug не изменился
  end
end
```

#### 2.1.3 Тесты для переименования - только slug

```ruby
context 'rename project slug only' do
  let(:project) { projects(:work_project) }

  it 'renames project slug through workflow' do
    old_name = project.name

    dispatch(callback_query: { data: "projects_rename:#{project.slug}" })
    dispatch(callback_query: { data: "projects_rename_slug:#{project.slug}" })

    expect do
      dispatch_message('new-slug')
    end.to change { project.reload.slug }.to('new-slug')

    expect(project.name).to eq(old_name) # name не изменилось
  end
end
```

#### 2.1.4 Тесты для переименования - оба (title + slug)

```ruby
context 'rename project both title and slug' do
  let(:project) { projects(:work_project) }

  it 'renames both title and slug through workflow' do
    dispatch(callback_query: { data: "projects_rename:#{project.slug}" })
    dispatch(callback_query: { data: "projects_rename_both:#{project.slug}" })

    # Вводим новое название
    response = dispatch_message('New Title')
    expect(response).not_to be_nil

    # Вводим новый slug
    expect do
      dispatch_message('new-slug')
    end.to change { project.reload.name }.to('New Title')
      .and change { project.slug }.to('new-slug')
  end

  it 'uses suggested slug when button clicked' do
    dispatch(callback_query: { data: "projects_rename:#{project.slug}" })
    dispatch(callback_query: { data: "projects_rename_both:#{project.slug}" })

    # Вводим новое название
    response = dispatch_message('My Awesome Project')

    # Извлекаем callback_data кнопки с suggested slug
    keyboard = response.first.dig(:reply_markup, :inline_keyboard)&.flatten || []
    suggested_button = keyboard.find { |btn| btn[:text].include?('Использовать') }

    # Нажимаем кнопку
    expect do
      dispatch(callback_query: { data: suggested_button[:callback_data] })
    end.to change { project.reload.slug }
  end
end
```

#### 2.1.5 Тесты для управления клиентом

```ruby
context 'client management' do
  let(:project) { projects(:work_project) }

  it 'sets client for project' do
    dispatch(callback_query: { data: "projects_client:#{project.slug}" })
    dispatch(callback_query: { data: "projects_client_edit:#{project.slug}" })

    expect do
      dispatch_message('ACME Corporation')
    end.to change { project.reload.client&.name }.to('ACME Corporation')
  end

  it 'removes client from project' do
    project.update(client: clients(:acme_corp))

    dispatch(callback_query: { data: "projects_client:#{project.slug}" })
    dispatch(callback_query: { data: "projects_client_delete:#{project.slug}" })

    expect do
      dispatch(callback_query: { data: "projects_client_delete_confirm:#{project.slug}" })
    end.to change { project.reload.client }.to(nil)
  end
end
```

#### 2.1.6 Тесты для удаления проекта

```ruby
context 'delete project' do
  let(:project) { projects(:work_project) }

  it 'deletes project through workflow' do
    dispatch(callback_query: { data: "projects_select:#{project.slug}" })
    dispatch(callback_query: { data: "projects_delete:#{project.slug}" })
    dispatch(callback_query: { data: "projects_delete_confirm:#{project.slug}" })

    expect do
      dispatch_message(project.name)
    end.to change(Project, :count).by(-1)
  end

  it 'cancels deletion on wrong name' do
    dispatch(callback_query: { data: "projects_select:#{project.slug}" })
    dispatch(callback_query: { data: "projects_delete:#{project.slug}" })
    dispatch(callback_query: { data: "projects_delete_confirm:#{project.slug}" })

    expect do
      dispatch_message('Wrong Name')
    end.not_to change(Project, :count)
  end
end
```

### 2.2 Запустить тесты

```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

**Ожидаемый результат**: Тесты падают из-за `NoMethodError: undefined method 'from_context'`

---

## Этап 3: Временное решение для совместимости

### 3.1 Добавить временный метод `from_context`

**Цель**: Сделать существующий код работающим с предупреждениями

**Файл**: `app/commands/base_command.rb`

```ruby
private

# ВРЕМЕННЫЙ МЕТОД - будет удален после рефакторинга ProjectsCommand
# TODO: Удалить после миграции на session/TelegramSession
def from_context(key)
  Rails.logger.warn "[DEPRECATED] from_context(#{key}) is deprecated, use session[#{key}] instead. Called from #{caller_locations(1, 1)[0]}"
  Bugsnag.notify(
    RuntimeError.new("Deprecated from_context usage"),
    metadata: {
      context_key: key,
      command: self.class.name,
      caller: caller_locations(1, 3).map(&:to_s)
    }
  )
  session[key]
end

# ВРЕМЕННЫЙ МЕТОД - будет удален после рефакторинга ProjectsCommand
# TODO: Удалить после миграции на session
def save_context_with_value(key, value)
  Rails.logger.warn "[DEPRECATED] save_context_with_value is deprecated. Called from #{caller_locations(1, 1)[0]}"
  session[key] = value
end
```

### 3.2 Исправить ProjectsCommand для работы с временными методами

**Файл**: `app/commands/projects_command.rb`

Заменить все вызовы `save_context(key, value)` на `save_context_with_value(key, value)`:

```ruby
# БЫЛО:
save_context(CONTEXT_CURRENT_PROJECT, slug)

# СТАЛО (временно):
save_context_with_value(CONTEXT_CURRENT_PROJECT, slug)
```

### 3.3 Запустить тесты

```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

**Ожидаемый результат**: Тесты проходят (green)

### 3.4 Commit

```bash
git add .
git commit -m "feat: add temporary from_context for backward compatibility

- Add deprecated from_context method to BaseCommand
- Add save_context_with_value helper
- Update ProjectsCommand to use temporary methods
- All methods log deprecation warnings and notify Bugsnag

This is a temporary solution before proper refactoring.
Tests are passing."
```

---

## Этап 4: Рефакторинг - миграция на session

### 4.1 Стратегия для ProjectsCommand

**Анализ операций**:

| Операция | Шагов | Данных | Рекомендация |
|----------|-------|---------|--------------|
| Создание проекта | 2 | 1 | `session` |
| Rename title | 2 | 1 | `session` |
| Rename slug | 2 | 1 | `session` |
| Rename both | 3 | 3 | `session` |
| Edit client | 2 | 1 | `session` |
| Delete client | 2 | 1 | `session` |
| Delete project | 3 | 1 | `session` |

**Вывод**: Используем `session` для всех операций (простые данные, 1-3 значения)

### 4.2 Рефакторинг создания проекта

```ruby
# БЫЛО:
def start_project_creation
  save_context(CONTEXT_AWAITING_PROJECT_NAME)
  respond_with :message, text: t('commands.projects.create.enter_name')
end

# СТАЛО:
def start_project_creation
  save_context :awaiting_project_name  # ✅ Только имя метода!
  respond_with :message, text: t('commands.projects.create.enter_name')
end

def awaiting_project_name(*name_parts)
  name = name_parts.join(' ').strip
  # ... валидация и создание проекта ...
  # Не нужно сохранять данные в session - операция завершается в одном методе
end
```

### 4.3 Рефакторинг переименования title

```ruby
def start_rename_title(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅ Данные в session
  save_context :awaiting_rename_title     # ✅ Только имя метода

  text = t('commands.projects.rename.enter_title', current_name: project.name)
  respond_with :message, text: text
end

def awaiting_rename_title(*title_parts)
  new_title = title_parts.join(' ').strip
  return handle_cancel_input :rename_title if cancel_input?(new_title)
  return respond_with :message, text: t('commands.projects.rename.error') if new_title.blank?

  current_slug = session[:current_project_slug]  # ✅ Чтение из session
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  old_name = project.name
  if project.update(name: new_title)
    session.delete(:current_project_slug)  # ✅ Очистка
    text = t('commands.projects.rename.success_title', old_name: old_name, new_name: new_title)
    respond_with :message, text: text
    show_project_menu(current_slug)
  else
    respond_with :message, text: t('commands.projects.rename.error')
  end
end
```

### 4.4 Рефакторинг переименования slug

```ruby
def start_rename_slug(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅
  save_context :awaiting_rename_slug      # ✅

  text = t('commands.projects.rename.enter_slug', current_slug: project.slug)
  respond_with :message, text: text
end

def awaiting_rename_slug(*slug_parts)
  new_slug = slug_parts.join(' ').strip
  return handle_cancel_input :rename_slug if cancel_input?(new_slug)

  current_slug = session[:current_project_slug]  # ✅
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

  if Project.where.not(id: project.id).exists?(slug: new_slug)
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
  end

  old_slug = project.slug
  if project.update(slug: new_slug)
    session.delete(:current_project_slug)  # ✅ Очистка
    text = t('commands.projects.rename.success_slug', old_slug: old_slug, new_slug: new_slug)
    respond_with :message, text: text
    show_project_menu(new_slug)
  else
    respond_with :message, text: t('commands.projects.rename.error')
  end
end
```

### 4.5 Рефакторинг переименования both (title + slug)

```ruby
def start_rename_both(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅
  save_context :awaiting_rename_both      # ✅

  text = t('commands.projects.rename.enter_title', current_name: project.name)
  respond_with :message, text: text
end

def awaiting_rename_both(*title_parts)
  new_title = title_parts.join(' ').strip
  return handle_cancel_input :rename_both if cancel_input?(new_title)
  return respond_with :message, text: t('commands.projects.rename.error') if new_title.blank?

  current_slug = session[:current_project_slug]  # ✅
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  # Сохраняем для следующего шага
  session[:new_project_title] = new_title  # ✅

  suggested_slug = Project.generate_unique_slug(new_title)
  session[:suggested_slug] = suggested_slug  # ✅

  save_context :awaiting_rename_both_step_2  # ✅

  text = t('commands.projects.rename.enter_slug', current_slug: current_slug)
  text += "\nПредложенный: #{suggested_slug}\n\n⚠️ Нажмите кнопку или введите свой вариант"

  buttons = [
    [{ text: t('commands.projects.rename.use_suggested'),
       callback_data: "projects_rename_use_suggested:#{current_slug}" }]
  ]

  respond_with :message, text: text, reply_markup: { inline_keyboard: buttons }
end

def awaiting_rename_both_step_2(*slug_parts)
  new_slug = slug_parts.join(' ').strip
  return handle_cancel_input :rename_both if cancel_input?(new_slug)

  current_slug = session[:current_project_slug]  # ✅
  new_title = session[:new_project_title]         # ✅

  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project && new_title

  return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

  if Project.where.not(id: project.id).exists?(slug: new_slug)
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
  end

  update_project_both(project, new_title, new_slug)

  # Очистка
  session.delete(:current_project_slug)  # ✅
  session.delete(:new_project_title)      # ✅
  session.delete(:suggested_slug)         # ✅
end

def projects_rename_use_suggested_callback_query(current_slug)
  unless current_slug
    Bugsnag.notify(RuntimeError.new('projects_rename_use_suggested_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end

  suggested_slug = session[:suggested_slug]  # ✅
  new_title = session[:new_project_title]     # ✅

  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project && new_title && suggested_slug

  update_project_both(project, new_title, suggested_slug)

  # Очистка
  session.delete(:current_project_slug)  # ✅
  session.delete(:new_project_title)      # ✅
  session.delete(:suggested_slug)         # ✅
end
```

### 4.6 Рефакторинг управления клиентом

```ruby
def start_client_edit(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅
  save_context :awaiting_client_name      # ✅

  current_client = project.client&.name || t('commands.projects.menu.no_client')
  text = t('commands.projects.client.enter_name', current_client: current_client)
  respond_with :message, text: text
end

def awaiting_client_name(*name_parts)
  client_name = name_parts.join(' ').strip
  return handle_cancel_input :client_name if cancel_input?(client_name)

  current_slug = session[:current_project_slug]  # ✅
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  # ... валидация и создание клиента ...

  session.delete(:current_project_slug)  # ✅ Очистка
  # ... ответ пользователю ...
end

# Аналогично для удаления клиента
def delete_client(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  if project.update(client: nil)
    session.delete(:current_project_slug)  # ✅ Очистка
    respond_with :message, text: t('commands.projects.client.delete_success')
    show_client_menu(slug)
  else
    show_error_message(t('commands.projects.client.delete_error'))
  end
end
```

### 4.7 Рефакторинг удаления проекта

```ruby
def confirm_project_deletion(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅
  stats = project.deletion_stats

  text = t('commands.projects.delete.confirm_first',
           name: project.name,
           time_shifts: stats[:time_shifts_count],
           memberships: stats[:memberships_count],
           invites: stats[:invites_count])

  buttons = [
    [{ text: t('commands.projects.delete.confirm_yes'), callback_data: "projects_delete_confirm:#{slug}" }],
    [{ text: t('commands.projects.delete.confirm_cancel'), callback_data: "projects_select:#{slug}" }]
  ]

  respond_with :message, text: text, reply_markup: { inline_keyboard: buttons }
end

def request_deletion_confirmation(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = slug  # ✅
  save_context :awaiting_delete_confirm   # ✅

  text = t('commands.projects.delete.confirm_final', name: project.name)
  respond_with :message, text: text
end

def awaiting_delete_confirm(*parts)
  confirmation = parts.join(' ').strip
  return handle_cancel_input :delete if cancel_input?(confirmation)

  current_slug = session[:current_project_slug]  # ✅
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  if confirmation != project.name
    respond_with :message, text: t('commands.projects.delete.name_mismatch')
    show_project_menu(current_slug)
    return
  end

  project_name = project.name
  project.destroy

  session.delete(:current_project_slug)  # ✅ Очистка

  respond_with :message, text: t('commands.projects.delete.success', name: project_name)
  show_projects_list
end
```

### 4.8 Удалить лишние save_context из меню

```ruby
def show_rename_menu(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  # УДАЛИТЬ: save_context(CONTEXT_CURRENT_PROJECT, slug)
  # Не нужно в меню - сохраняем только при переходе к действию

  menu_text = t('commands.projects.rename.title', name: project.name)
  buttons = [
    [{ text: t('commands.projects.rename.title_button'), callback_data: "projects_rename_title:#{slug}" }],
    [{ text: t('commands.projects.rename.slug_button'), callback_data: "projects_rename_slug:#{slug}" }],
    [{ text: t('commands.projects.rename.both_button'), callback_data: "projects_rename_both:#{slug}" }],
    [{ text: t('commands.projects.rename.cancel_button'), callback_data: "projects_select:#{slug}" }]
  ]

  respond_with :message, text: menu_text, reply_markup: { inline_keyboard: buttons }
end

def show_client_menu(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  # УДАЛИТЬ: save_context(CONTEXT_CURRENT_PROJECT, slug)

  current_client = project.client&.name || t('commands.projects.menu.no_client')
  text = t('commands.projects.client.menu_title',
           project_name: project.name,
           client_name: current_client)

  buttons = [
    [{ text: t('commands.projects.client.edit_button'), callback_data: "projects_client_edit:#{slug}" }]
  ]

  buttons << [{ text: t('commands.projects.client.delete_button'), callback_data: "projects_client_delete:#{slug}" }] if project.client
  buttons << [{ text: t('commands.projects.menu.back_button'), callback_data: "projects_select:#{slug}" }]

  respond_with :message, text: text, reply_markup: { inline_keyboard: buttons }
end
```

### 4.9 Удалить неиспользуемые константы

```ruby
# УДАЛИТЬ из ProjectsCommand:
# CONTEXT_CURRENT_PROJECT = :current_project_slug
# CONTEXT_RENAME_ACTION = :rename_action
# CONTEXT_SUGGESTED_SLUG = :suggested_slug
# CONTEXT_AWAITING_RENAME_BOTH_STEP_2 = :awaiting_rename_both_step_2

# ОСТАВИТЬ только для provides_context_methods:
CONTEXT_AWAITING_PROJECT_NAME = :awaiting_project_name
CONTEXT_AWAITING_RENAME_TITLE = :awaiting_rename_title
CONTEXT_AWAITING_RENAME_SLUG = :awaiting_rename_slug
CONTEXT_AWAITING_RENAME_BOTH = :awaiting_rename_both
CONTEXT_AWAITING_CLIENT_NAME = :awaiting_client_name
CONTEXT_AWAITING_CLIENT_DELETE_CONFIRM = :awaiting_client_delete_confirm
CONTEXT_AWAITING_DELETE_CONFIRM = :awaiting_delete_confirm
```

### 4.10 Запустить тесты

```bash
bundle exec rspec spec/controllers/telegram/webhook/projects_command_spec.rb
```

**Ожидаемый результат**: Все тесты проходят (green)

### 4.11 Commit

```bash
git add app/commands/projects_command.rb
git commit -m "refactor: migrate ProjectsCommand to use session instead of from_context

- Replace all from_context() calls with session[]
- Replace save_context(key, value) with session[key] = value
- Add session cleanup after operations complete
- Remove unused context constants
- Keep only context method name constants

All tests passing. No deprecated methods used."
```

---

## Этап 5: Удаление временных методов

### 5.1 Проверить отсутствие использования

```bash
# Проверить from_context
grep -r "from_context" app/commands/

# Проверить save_context_with_value
grep -r "save_context_with_value" app/commands/
```

**Ожидаемый результат**: Ничего не найдено (кроме определения в BaseCommand)

### 5.2 Удалить временные методы

**Файл**: `app/commands/base_command.rb`

```ruby
# УДАЛИТЬ:
# def from_context(key)
# def save_context_with_value(key, value)
```

### 5.3 Запустить все тесты

```bash
bundle exec rspec spec/controllers/telegram/webhook/
```

**Ожидаемый результат**: Все тесты проходят

### 5.4 Commit

```bash
git add app/commands/base_command.rb
git commit -m "refactor: remove deprecated from_context and save_context_with_value

- Delete from_context temporary method
- Delete save_context_with_value temporary method
- All commands now use proper session management

All tests passing."
```

---

## Этап 6: Финальная проверка и документация

### 6.1 Полный набор тестов

```bash
# Все тесты Telegram
bundle exec rspec spec/controllers/telegram/

# Все тесты проекта
bundle exec rspec
```

### 6.2 Проверка логов

```bash
# Запустить dev сервер
./bin/dev

# Вручную протестировать все операции ProjectsCommand
# Проверить логи на отсутствие [DEPRECATED]
tail -f log/development.log | grep DEPRECATED
```

### 6.3 Обновить документацию

**Файл**: `docs/development/telegram-session-management.md`

Добавить раздел с примером ProjectsCommand:

```markdown
## Примеры из ProjectsCommand

### Правильное использование session для многошаговых операций

```ruby
# Переименование проекта (оба: название и slug)
def start_rename_both(slug)
  session[:current_project_slug] = slug  # ✅ Данные в session
  save_context :awaiting_rename_both      # ✅ Только имя метода
  # ...
end

def awaiting_rename_both(*title_parts)
  current_slug = session[:current_project_slug]  # ✅ Чтение
  session[:new_project_title] = new_title         # ✅ Сохранение
  save_context :awaiting_rename_both_step_2      # ✅
  # ...
end

def awaiting_rename_both_step_2(*slug_parts)
  current_slug = session[:current_project_slug]  # ✅
  new_title = session[:new_project_title]         # ✅
  # ... обработка ...

  # Очистка
  session.delete(:current_project_slug)  # ✅
  session.delete(:new_project_title)      # ✅
  session.delete(:suggested_slug)         # ✅
end
```
```

### 6.4 Создать Pull Request

```bash
git push origin refactor/projects-command-session-management
```

**Описание PR**:

```markdown
## Рефакторинг управления сессиями в ProjectsCommand

### Проблема
ProjectsCommand использовал несуществующий метод `from_context()` и неправильно
вызывал `save_context()` с двумя аргументами для хранения данных.

### Решение
- Мигрировали все операции на использование `session[]`
- Исправили все вызовы `save_context()` - только имя метода
- Добавили очистку session после операций
- Удалили временные deprecated методы

### Покрытие тестами
- Добавлены интеграционные тесты для всех многошаговых операций
- Все тесты проходят

### Checklist
- [x] Все тесты проходят
- [x] Документация обновлена
- [x] Код проверен вручную
- [x] Deprecated методы удалены
- [x] Session корректно очищается
```

---

## Этап 7: Code Review и Merge

### 7.1 Checklist для reviewer

- [ ] Все вызовы `save_context` имеют только один аргумент
- [ ] Нет вызовов `from_context`
- [ ] Session корректно очищается (`session.delete`)
- [ ] Тесты покрывают все многошаговые операции
- [ ] Документация актуальна

### 7.2 Merge

```bash
git checkout master
git merge refactor/projects-command-session-management
git push origin master
```

### 7.3 Deploy и мониторинг

```bash
# Deploy на production
# Мониторинг Bugsnag - проверить отсутствие NoMethodError
```

---

## Критерии завершения

### Код
- [ ] Метод `from_context` полностью удален
- [ ] Метод `save_context_with_value` удален
- [ ] Все вызовы `save_context` - только с одним аргументом
- [ ] Все данные в `session[key] = value`
- [ ] Session очищается после операций

### Тесты
- [ ] Создание проекта покрыто
- [ ] Переименование (title, slug, both) покрыто
- [ ] Управление клиентом покрыто
- [ ] Удаление проекта покрыто
- [ ] Все тесты проходят

### Документация
- [ ] Примеры ProjectsCommand в документации
- [ ] CHANGELOG обновлен
- [ ] PR описание полное

### Production
- [ ] Deploy успешен
- [ ] Нет ошибок в Bugsnag
- [ ] Все операции протестированы вручную

---

## Риски и митигация

### Риск 1: Потеря данных в session
**Вероятность**: Низкая
**Влияние**: Среднее
**Митигация**: Тщательное тестирование, проверка очистки session

### Риск 2: Регрессия в других командах
**Вероятность**: Очень низкая
**Влияние**: Среднее
**Митигация**: Запуск полного набора тестов, code review

### Риск 3: Неполное покрытие тестами
**Вероятность**: Средняя
**Влияние**: Высокое
**Митигация**: TDD подход, написание тестов ДО рефакторинга

---

## Метрики успеха

- ✅ 0 вызовов `from_context` в коде
- ✅ 0 вызовов `save_context` с двумя аргументами
- ✅ 100% тестового покрытия многошаговых операций
- ✅ 0 ошибок NoMethodError в Bugsnag после deploy
- ✅ Все операции ProjectsCommand работают корректно

---

## Заключение

После выполнения плана:
1. ProjectsCommand будет использовать правильные паттерны работы с сессиями
2. Код будет соответствовать документации и best practices
3. Все операции будут покрыты тестами
4. Технический долг будет устранен
5. Риск критических ошибок в production будет исключен
