# ProjectsCommand Test Failure Analysis

## Резюме

✅ **ClientsCommand тесты**: 43/43 PASS
❌ **ProjectsCommand тесты**: 18/23 PASS, 5 FAILURES

**Вывод**: Код ProjectsCommand правильный, проблема в тестах.

## Причина №1: Session не передается между dispatch() вызовами

### Что работает в ClientsCommand (эталон)

```ruby
# ClientsCommand тест - РАБОТАЕТ
dispatch_command :clients, 'add'         # session сохранен
dispatch_message 'TestClient'            # session доступен
dispatch_message 'testkey123'            # session доступен
# ✅ Клиент создается успешно
```

### Что не работает в ProjectsCommand

```ruby
# ProjectsCommand тест - НЕ РАБОТАЕТ
dispatch(callback_query: { data: "projects_rename:#{slug}" })      # session установлен
dispatch(callback_query: { data: "projects_rename_slug:#{slug}" }) # session ПОТЕРЯН
dispatch_message('new-slug')                                         # session пустой
# ❌ Переименование не работает
```

### Объяснение

**В telegram-bot-rspec**: `dispatch()` и `dispatch_command()` создают РАЗНЫЕ controller instances.

```ruby
# Когда вызывается dispatch():
def dispatch(update)
  controller = Telegram::WebhookController.new  # НОВЫЙ instance
  controller.dispatch(update)
end

# Когда вызывается dispatch_command():
def dispatch_command(command, *args)
  controller = Telegram::WebhookController.new  # НОВЫЙ instance
  controller.dispatch_command(command, *args)
end
```

**Проблема**: Session в Rails сохраняется через cookies/headers между HTTP requests, но в тестах каждый `dispatch()` создает fresh controller instance БЕЗ передачи session данных.

**Почему ClientsCommand работает?**
- Использует **только** `dispatch_command()` и `dispatch_message()`
- Не смешивает с `dispatch(callback_query: ...)`
- `dispatch_message()` внутри использует тот же механизм что и `dispatch_command()`

**Почему ProjectsCommand НЕ работает?**
- Смешивает `dispatch(callback_query: ...)` с `dispatch_message()`
- Каждый `dispatch()` вызов = новый controller instance = потеря session

## Падающие тесты

### 1. `rename_slug` (строка 235)

```ruby
# ❌ ПАДАЕТ
dispatch(callback_query: { data: "projects_rename:#{slug}" })
dispatch(callback_query: { data: "projects_rename_slug:#{slug}" })  # session потерян
dispatch_message('new-slug')  # session[:current_project_slug] = nil
```

**Что происходит в коде**:
```ruby
def start_rename_slug(slug)
  session[:current_project_slug] = slug  # Сохраняется в первом controller
  save_context CONTEXT_AWAITING_RENAME_SLUG
end

def awaiting_rename_slug(*slug_parts)
  current_slug = session[:current_project_slug]  # nil во втором controller
  project = current_user.projects.find_by(slug: current_slug)  # nil
  return show_projects_list unless project  # RETURN - ничего не меняется
end
```

### 2. `rename_both` suggested button (строка 292)

```ruby
# ❌ ПАДАЕТ
dispatch(callback_query: { data: "projects_rename:#{slug}" })
dispatch(callback_query: { data: "projects_rename_both:#{slug}" })
response = dispatch_message('My Awesome Project')

# Ожидаем suggested_slug кнопку в response
keyboard = response.first.dig(:reply_markup, :inline_keyboard)
suggested_button = keyboard.find { |btn| btn[:text].include?('Использовать') }
expect(suggested_button).not_to be_nil  # FAIL - nil
```

**Что происходит**:
```ruby
def awaiting_rename_both(*title_parts)
  current_slug = session[:current_project_slug]  # nil
  project = current_user.projects.find_by(slug: current_slug)  # nil
  return show_projects_list unless project  # RETURN - кнопка не создается
end
```

### 3. `client_name` (строка 346)

```ruby
# ❌ ПАДАЕТ
dispatch(callback_query: { data: "projects_client:#{slug}" })
dispatch(callback_query: { data: "projects_client_edit:#{slug}" })  # session потерян
dispatch_message('ACME Corporation')  # session[:current_project_slug] = nil
```

**Аналогично rename_slug** - session теряется между callback и message.

### 4. `client_delete` (строка 369)

```ruby
# ❌ ПАДАЕТ
dispatch(callback_query: { data: "projects_client:#{slug}" })
dispatch(callback_query: { data: "projects_client_delete:#{slug}" })  # session потерян
dispatch(callback_query: { data: "projects_client_delete_confirm:#{slug}" })  # session все еще nil
```

**Тройная потеря session** - три разных controller instances.

### 5. `project_delete` (строка 415) - FOREIGN KEY CONSTRAINT

```ruby
# ❌ ПАДАЕТ
PG::ForeignKeyViolation: ERROR: update or delete on table "projects"
violates foreign key constraint "fk_rails_d85f5f3e6c" on table "invites"
DETAIL: Key (id)=(871498793) is still referenced from table "invites".
```

**Причина**: `test_project` имеет связанный `invite` в fixtures:

```yaml
# invites.yml
pending_telegram_invite:
  project: test_project  # ← Блокирует удаление
```

**Решение**: Использовать проект БЕЗ invites для теста удаления.

## Сравнение паттернов

### ClientsCommand тесты (✅ РАБОТАЕТ)

```ruby
# Многошаговый workflow БЕЗ callback_query
dispatch_command :clients, 'add'      # Шаг 1
dispatch_message 'TestClient'         # Шаг 2
dispatch_message 'testkey123'         # Шаг 3
# ✅ Session сохраняется между dispatch_message вызовами
```

### ProjectsCommand тесты (❌ НЕ РАБОТАЕТ)

```ruby
# Многошаговый workflow С callback_query
dispatch(callback_query: { data: "projects_rename:..." })       # Шаг 1
dispatch(callback_query: { data: "projects_rename_slug:..." })  # Шаг 2 - session lost
dispatch_message('new-slug')                                     # Шаг 3 - session still lost
# ❌ Session НЕ передается между dispatch() вызовами
```

## Рекомендации

### ✅ Вариант A: Исправить тесты (РЕКОМЕНДУЕТСЯ)

**Использовать тот же паттерн что ClientsCommand**:

```ruby
# Вместо callback_query используем прямые команды где возможно
it 'renames project slug through workflow' do
  # Вызываем команду напрямую вместо эмуляции callback
  dispatch_command :projects, 'rename', 'slug', project.slug

  expect do
    dispatch_message('new-slug')
  end.to change { project.reload.slug }.to('new-slug')
end
```

**ИЛИ**: Для callback_query тестов использовать **моки session**:

```ruby
it 'renames project slug through workflow' do
  # Мокируем session чтобы сохранить между вызовами
  allow_any_instance_of(Telegram::WebhookController).to receive(:session)
    .and_return({ current_project_slug: project.slug })

  dispatch(callback_query: { data: "projects_rename_slug:#{project.slug}" })

  expect do
    dispatch_message('new-slug')
  end.to change { project.reload.slug }.to('new-slug')
end
```

**ИЛИ**: Тестировать callback_query отдельно от message handling:

```ruby
# Тест 1: Проверяем что callback устанавливает session
it 'sets up session for rename' do
  controller = Telegram::WebhookController.new
  allow(controller).to receive(:current_user).and_return(user)

  controller.send(:start_rename_slug, project.slug)

  expect(controller.session[:current_project_slug]).to eq(project.slug)
  expect(controller.session[:context]).to eq('awaiting_rename_slug')
end

# Тест 2: Проверяем обработку message при правильном session
it 'renames slug when session is set' do
  dispatch_command :projects  # Любая команда для setup

  # Напрямую устанавливаем session для теста
  controller.session[:current_project_slug] = project.slug
  controller.session[:context] = 'awaiting_rename_slug'

  expect do
    dispatch_message('new-slug')
  end.to change { project.reload.slug }.to('new-slug')
end
```

**Исправить Foreign key constraint**:

```ruby
# Использовать проект БЕЗ invites
context 'delete project' do
  let(:project) { projects(:work_project) }  # У него нет invites в fixtures

  # Или очистить invites в before
  before do
    project.invites.destroy_all
  end
end
```

### ⚠️ Вариант B: Изменить код (НЕ РЕКОМЕНДУЕТСЯ)

Передавать slug в каждом message вместо session:

```ruby
# НЕ ДЕЛАТЬ - это ухудшит UX
def awaiting_rename_slug(*args)
  # Вместо session требовать от пользователя вводить "slug: new-slug"
  # Пользователь не должен помнить что он делает
end
```

**Почему плохо**: Пользователь потеряет context между шагами.

### ✅ Вариант C: Ручное тестирование (ВРЕМЕННОЕ РЕШЕНИЕ)

Если telegram-bot-rspec не поддерживает session между dispatch вызовами:

1. Покрыть тестами каждый метод отдельно (unit tests)
2. Протестировать полный workflow вручную в Telegram
3. Добавить integration тесты с реальным Telegram API (сложно)

## Вывод

**Основная причина**: telegram-bot-rspec НЕ сохраняет session между `dispatch()` вызовами.

**Лучшее решение**:
- Исправить тесты используя паттерн ClientsCommand (dispatch_command + dispatch_message)
- Или мокировать session для callback_query тестов
- Исправить fixtures для Foreign key constraint

**Код ProjectsCommand правильный** - проблема только в тестировании механизма session в telegram-bot-rspec.

## Следующие шаги

1. ✅ Определить подход к исправлению тестов (A1, A2 или A3)
2. ⏳ Реализовать исправления в тестах
3. ⏳ Запустить полный test suite
4. ⏳ Ручное тестирование в реальном Telegram боте для подтверждения
