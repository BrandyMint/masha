# Правила работы с telegram callback, callback_query

## Основной принцип

**Один callback_query метод = один тип действия**

Каждый callback должен обрабатываться отдельным методом. Telegram-бот gem автоматически маршрутизирует callback на нужный метод по префиксу.

## Категорический запрет

### 1. Ручной разбор callback_data в едином методе

Запрещено делать любой ручной разбор callback (case/when, if/elsif, start_with?, regex):

**❌ Неправильно (case/when):**
```ruby
def projects_callback_query(data = nil)
  case data
  when 'projects:create'
    start_project_creation
  when /^projects:select:(.+)$/
    show_project_menu(Regexp.last_match(1))
  when 'projects:list'
    show_projects_list
  end
end
```

**❌ Неправильно (условия с start_with?):**
```ruby
def report_callback_query(data = nil)
  return unless data&.start_with?('report_help_')

  section = data.sub('report_help_', '')
  case section
  when 'periods'
    show_periods_help
  when 'filters'
    show_filters_help
  end
end
```

**❌ Неправильно (цепочка if/elsif):**
```ruby
def settings_callback_query(data = nil)
  if data == 'settings:theme'
    show_theme_settings
  elsif data == 'settings:lang'
    show_lang_settings
  elsif data.match?(/^settings:save:(.+)$/)
    save_settings(Regexp.last_match(1))
  end
end
```

### 2. Множественные разделители в callback_data

Запрещено использовать более одного разделителя (`:` или `_`) в callback_data:

**❌ Неправильно:**
```ruby
callback_data: "projects:rename:#{slug}"       # два двоеточия
callback_data: "projects:client:#{slug}"       # два двоеточия
callback_data: "report_help_periods"           # два подчеркивания
callback_data: "users_add_role:owner"          # смешанные разделители
```

**✅ Правильно:**
```ruby
callback_data: "projects_rename:#{slug}"       # один разделитель
callback_data: "projects_client:#{slug}"       # один разделитель
callback_data: "report_periods"                # без разделителей или один
callback_data: "users_role:owner"              # один разделитель
```

## Правильный подход

### Принцип работы

Telegram-бот gem автоматически маршрутизирует callback по префиксу:

1. Бот получает `callback_data: "projects_rename:my-project"`
2. Извлекает префикс до первого разделителя: `projects_rename`
3. Добавляет суффикс `_callback_query`
4. Вызывает метод `projects_rename_callback_query("my-project")`

### Примеры правильной реализации

**Пример 1: Меню проекта**

```ruby
# В команде создаем кнопки
buttons = [
  [{ text: '✏️ Переименовать', callback_data: "projects_rename:#{slug}" }],
  [{ text: '🏢 Клиент', callback_data: "projects_client:#{slug}" }],
  [{ text: '🗑️ Удалить', callback_data: "projects_delete:#{slug}" }],
  [{ text: '📋 Список', callback_data: 'projects_list' }]
]

respond_with :message,
             text: menu_text,
             reply_markup: { inline_keyboard: buttons }

# Для каждой кнопки - отдельный метод
def projects_rename_callback_query(slug)
  show_rename_menu(slug)
end

def projects_client_callback_query(slug)
  show_client_menu(slug)
end

def projects_delete_callback_query(slug)
  confirm_project_deletion(slug)
end

def projects_list_callback_query
  show_projects_list
end
```

**Пример 2: Справочная система**

```ruby
# Кнопки навигации по справке
buttons = [
  [{ text: '📅 Периоды', callback_data: 'report_periods' }],
  [{ text: '🔍 Фильтры', callback_data: 'report_filters' }],
  [{ text: '⚙️ Опции', callback_data: 'report_options' }],
  [{ text: '💡 Примеры', callback_data: 'report_examples' }]
]

# Отдельный метод для каждого раздела справки
def report_periods_callback_query
  show_periods_help
end

def report_filters_callback_query
  show_filters_help
end

def report_options_callback_query
  show_options_help
end

def report_examples_callback_query
  show_examples_help
end
```

**Пример 3: Добавление пользователя с ролью**

```ruby
# Выбор роли пользователя
buttons = [
  [{ text: '👑 Владелец', callback_data: 'users_role:owner' }],
  [{ text: '👁️ Наблюдатель', callback_data: 'users_role:viewer' }],
  [{ text: '👤 Участник', callback_data: 'users_role:member' }]
]

# Один метод для обработки выбора роли
def users_role_callback_query(role)
  data = telegram_session_data
  add_user_to_project(data['project_slug'], data['username'], role)
end
```

### Когда нужны параметры

Если callback_data содержит параметр после разделителя, он передается в метод как аргумент:

```ruby
# Без параметров
callback_data: 'projects_list'
def projects_list_callback_query
  # data = nil
end

# С одним параметром
callback_data: "projects_rename:#{slug}"
def projects_rename_callback_query(slug)
  # slug = значение после двоеточия
end

# С несколькими параметрами (через парсинг строки)
callback_data: "action_data:param1,param2"
def action_data_callback_query(params)
  param1, param2 = params.split(',')
end
```

### Эталонные команды

Используй как примеры правильной реализации:
- **AddCommand** - простой callback с параметром
- **EditCommand** - несколько разных callback в одной команде
- **UsersCommand** - callback с session state

## Почему это важно

### 1. Автоматическая маршрутизация

Telegram-бот gem использует **convention over configuration**. Когда ты пишешь:
```ruby
callback_data: "projects_rename:#{slug}"
```

Gem автоматически:
- Разбирает префикс (`projects_rename`)
- Находит метод `projects_rename_callback_query`
- Передает параметр (`slug`)
- Вызывает метод

Если ты делаешь ручной разбор - ты **дублируешь логику gem** и ломаешь convention.

### 2. Читаемость и поддержка

```ruby
# ❌ Плохо: один метод на 100+ строк с ручным разбором
def projects_callback_query(data)
  case data
  when 'create' then ...      # 20 строк
  when /^rename:/ then ...     # 30 строк
  when /^delete:/ then ...     # 25 строк
  when /^client:/ then ...     # 35 строк
  end
end

# ✅ Хорошо: четыре метода по 15-20 строк
def projects_create_callback_query    # 15 строк
def projects_rename_callback_query     # 20 строк
def projects_delete_callback_query     # 18 строк
def projects_client_callback_query     # 22 строк
```

### 3. Тестирование

С отдельными методами проще писать тесты:

```ruby
# ✅ Легко тестировать
it 'handles rename callback' do
  dispatch(callback_query: {
    data: "projects_rename:#{project.slug}"
  })
  expect(response).to include('Переименовать проект')
end

# ❌ Сложно тестировать ручной разбор
it 'handles various callbacks' do
  # Нужно тестировать весь case/when целиком
  # Много моков, сложная логика
end
```

## Типичные ошибки

### Ошибка 1: "Но у меня всего 3-4 варианта"

**Неправильная мысль:** "Зачем создавать 4 метода, если можно один case/when?"

**Правильный подход:** Даже для 2-3 вариантов делай отдельные методы. Это:
- Соответствует convention проекта
- Проще расширять (добавил кнопку = добавил метод)
- Понятнее новичкам в команде

### Ошибка 2: "Мне нужно несколько параметров"

**Неправильно:**
```ruby
callback_data: "action:param1:param2:param3"  # три разделителя!
```

**Правильно - объедини параметры:**
```ruby
# Вариант 1: через запятую
callback_data: "action:#{param1},#{param2},#{param3}"
def action_callback_query(params)
  param1, param2, param3 = params.split(',')
end

# Вариант 2: через session
save_context(:action_data, { param1: x, param2: y })
callback_data: "action:confirm"
def action_callback_query(action)
  data = from_context(:action_data)
  # используй data[:param1], data[:param2]
end
```

### Ошибка 3: "Разные действия с одним параметром"

**Неправильно:**
```ruby
# Хочу и показать и удалить проект, один slug
callback_data: "project:show:#{slug}"   # два разделителя!
callback_data: "project:delete:#{slug}" # два разделителя!
```

**Правильно - разные префиксы:**
```ruby
callback_data: "project_show:#{slug}"     # один разделитель
callback_data: "project_delete:#{slug}"   # один разделитель

def project_show_callback_query(slug)
  show_project(slug)
end

def project_delete_callback_query(slug)
  delete_project(slug)
end
```

## Миграция legacy кода

Если встретишь код с нарушениями:

1. **Найди все case/when или if/elsif** в `*_callback_query` методах
2. **Для каждого варианта** создай отдельный метод
3. **Обнови все callback_data** на использование правильного префикса
4. **Проверь тесты** - обнови dispatch вызовы на новые prefixes

Пример миграции:

```ruby
# Было
def report_callback_query(data)
  return unless data&.start_with?('report_help_')
  section = data.sub('report_help_', '')
  # ... обработка section
end

# Стало
def report_periods_callback_query
  show_periods_help
end

def report_filters_callback_query
  show_filters_help
end

# И т.д. для каждого раздела
```

## Краткая памятка

### ✅ Делай так

```ruby
# 1. Один callback = один метод
callback_data: "projects_rename:#{slug}"
def projects_rename_callback_query(slug)

# 2. Максимум один разделитель
callback_data: "action:param"          # ✅
callback_data: "action_name"           # ✅
callback_data: "action"                # ✅

# 3. Несколько параметров через запятую или session
callback_data: "action:#{p1},#{p2}"    # ✅
callback_data: "confirm"               # ✅ + session
```

### ❌ Не делай так

```ruby
# 1. Ручной разбор callback
def projects_callback_query(data)
  case data                             # ❌
  when 'create' then ...
  end
end

# 2. Множественные разделители
callback_data: "projects:rename:slug"   # ❌ два двоеточия
callback_data: "report_help_periods"    # ❌ два подчеркивания

# 3. Условия с разбором
def report_callback_query(data)
  if data.start_with?('help_')          # ❌
    ...
  end
end
```

### Быстрая проверка

Перед коммитом проверь:

1. ✅ Нет ли `case`/`when` в `*_callback_query` методах?
2. ✅ Нет ли `if`/`elsif` для разбора callback_data?
3. ✅ Нет ли `start_with?`, `match?`, `sub` для парсинга префиксов?
4. ✅ Максимум один разделитель в каждом `callback_data`?
5. ✅ Каждому callback соответствует отдельный метод?

Если хоть на один вопрос ответ "нет" - рефактори код!


