# Правила работы с telegram callback, callback_query

## Основной принцип

**Один callback_query метод = один тип действия**

Каждый callback должен обрабатываться отдельным методом. Telegram-бот gem автоматически маршрутизирует callback на нужный метод по префиксу.

## ⚠️ КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА

### Правило 1: Callback методы ДОЛЖНЫ быть публичными!

**Все методы `*_callback_query` должны быть определены ДО секции `private`!**

Система регистрации команд (`CommandRegistry`) ищет callback методы через `public_instance_methods`. Если метод определен после `private`, он **НЕ будет зарегистрирован** и callback **НЕ сработает**.

**❌ Неправильно - callback методы НЕ сработают:**
```ruby
class RateCommand < BaseCommand
  def call(*args)
    # ...
  end

  private  # ❌ callback методы ниже НЕ будут зарегистрированы!

  def rate_select_project_callback_query(slug)
    # Этот метод НЕ будет найден системой!
  end

  def rate_view_list_callback_query(slug)
    # Этот метод НЕ будет найден системой!
  end
end
```

**✅ Правильно - callback методы сработают:**
```ruby
class RateCommand < BaseCommand
  def call(*args)
    # ...
  end

  # Callback методы ПЕРЕД private - они публичные!
  def rate_select_project_callback_query(slug)
    # Этот метод будет найден системой ✅
  end

  def rate_view_list_callback_query(slug)
    # Этот метод будет найден системой ✅
  end

  private  # ✅ private идет ПОСЛЕ всех callback методов

  def helper_method
    # Вспомогательные методы
  end
end
```

**Структура команды:**
```ruby
class YourCommand < BaseCommand
  # 1. Метод call
  def call(*args)
  end

  # 2. Публичные callback методы (до private!)
  def action_callback_query(data)
  end

  def another_callback_query(data)
  end

  # 3. Контекстные методы (если есть)
  def awaiting_input(*args)
  end

  private  # 4. ТОЛЬКО ЗДЕСЬ начинается private секция

  # 5. Вспомогательные приватные методы
  def helper_method
  end
end
```

### Правило 2: Двоеточие в callback_data обязательно ВСЕГДА

**Двоеточие в callback_data обязательно ВСЕГДА, даже без параметров!**

Для того чтобы срабатывал метод `#{context}_callback_query`, в `callback_data` **ОБЯЗАТЕЛЬНО** должно быть двоеточие. Даже если параметр отсутствует, двоеточие должно быть в конце.

**❌ Неправильно:**
```ruby
callback_data: "projects_list"        # метод НЕ сработает!
callback_data: "projects_create"      # метод НЕ сработает!
```

**✅ Правильно:**
```ruby
callback_data: "projects_list:"       # метод сработает
callback_data: "projects_create:"     # метод сработает
callback_data: "projects_rename:#{slug}"  # метод сработает с параметром
```

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
  [{ text: '📋 Список', callback_data: 'projects_list:' }]  # двоеточие обязательно!
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
  [{ text: '📅 Периоды', callback_data: 'report_periods:' }],      # двоеточие обязательно!
  [{ text: '🔍 Фильтры', callback_data: 'report_filters:' }],      # двоеточие обязательно!
  [{ text: '⚙️ Опции', callback_data: 'report_options:' }],        # двоеточие обязательно!
  [{ text: '💡 Примеры', callback_data: 'report_examples:' }]      # двоеточие обязательно!
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
  [{ text: '👑 Владелец', callback_data: 'users_add_role:owner' }],
  [{ text: '👁️ Наблюдатель', callback_data: 'users_add_role:watcher' }],
  [{ text: '👤 Участник', callback_data: 'users_add_role:participant' }]
]

# Один метод для обработки выбора роли
# role - аргумент из callback_data после двоеточия
def users_add_role_callback_query(role)
  add_user_with_role(role)
end
```

### Когда нужны параметры

Если callback_data содержит параметр после разделителя, он передается в метод как аргумент.

**ВАЖНО:** Двоеточие обязательно ВСЕГДА, даже если параметр отсутствует!

```ruby
# Без параметров (двоеточие в конце ОБЯЗАТЕЛЬНО!)
callback_data: 'projects_list:'
def projects_list_callback_query(data = nil)
  # data = nil или пустая строка
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
- **ProjectsCommand** - множественные callback с параметрами

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

**ВАЖНО:** Gem ищет двоеточие для определения префикса. Без двоеточия метод `#{context}_callback_query` **НЕ сработает**!

```ruby
callback_data: "projects_list"   # ❌ НЕ сработает - нет двоеточия
callback_data: "projects_list:"  # ✅ Сработает - есть двоеточие
```

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

**Правильно - объедини параметры через запятую:**
```ruby
callback_data: "action:#{param1},#{param2},#{param3}"
def action_callback_query(data)
  # data содержит строку "param1,param2,param3"
  param1, param2, param3 = data.split(',')
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

# 2. Двоеточие ОБЯЗАТЕЛЬНО всегда (даже без параметров!)
callback_data: "action:param"          # ✅ с параметром
callback_data: "action_name:"          # ✅ без параметра, но с двоеточием!
callback_data: "action:"               # ✅ без параметра, но с двоеточием!

# 3. Несколько параметров через запятую
callback_data: "action:#{p1},#{p2}"    # ✅
```

### ❌ Не делай так

```ruby
# 1. Отсутствие двоеточия (метод НЕ сработает!)
callback_data: "projects_list"          # ❌ метод НЕ сработает!
callback_data: "action_name"            # ❌ метод НЕ сработает!
callback_data: "confirm"                # ❌ метод НЕ сработает!

# 2. Ручной разбор callback
def projects_callback_query(data)
  case data                             # ❌
  when 'create' then ...
  end
end

# 3. Множественные разделители
callback_data: "projects:rename:slug"   # ❌ два двоеточия
callback_data: "report_help_periods"    # ❌ два подчеркивания

# 4. Условия с разбором
def report_callback_query(data)
  if data.start_with?('help_')          # ❌
    ...
  end
end
```

### Быстрая проверка

Перед коммитом проверь:

1. ✅ **Все callback методы определены ДО `private`?** (самая частая ошибка!)
2. ✅ Есть ли двоеточие в КАЖДОМ `callback_data` (даже без параметров)?
3. ✅ Нет ли `case`/`when` в `*_callback_query` методах?
4. ✅ Нет ли `if`/`elsif` для разбора callback_data?
5. ✅ Нет ли `start_with?`, `match?`, `sub` для парсинга префиксов?
6. ✅ Максимум один разделитель в каждом `callback_data`?
7. ✅ Каждому callback соответствует отдельный метод?

Если хоть на один вопрос ответ "нет" - рефактори код!

### Проверка регистрации callback методов

Чтобы убедиться, что все callback методы зарегистрированы:

```ruby
# В rails console или через ruby -e
require_relative 'config/environment'

# Проверить конкретную команду
command = Telegram::CommandRegistry.get(:rate)
puts command.callback_method_names.inspect

# Должны быть все методы вида *_callback_query
# Если список пустой или не хватает методов - они в private!
```


