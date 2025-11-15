# Управление сессиями в Telegram боте

## Обзор

В Telegram боте используется двухуровневая система управления сессиями:
- **`session`** - базовое хранилище от telegram-bot gem
- **`TelegramSession`** - высокоуровневая абстракция для сложных операций

## Session (базовый уровень)

`session` предоставляет низкоуровневое хранилище ключ-значение в Rails session.

### Когда использовать `session`

#### ✅ **Простые временные данные (1-2 значения)**
```ruby
# Промежуточные данные в диалоге
session[:client_name] = "ООО Ромашка"
session[:edit_client_key] = "client123"

# Временные флаги
session[:showing_help] = true
```

#### ✅ **Контекст telegram-bot gem**
```ruby
# Обязательно: Сохранение контекста команды
save_context :add_client_name
save_context :edit_project_name

# Проверка контекста
context = session[:context]
```

#### ✅ **Однократные операции**
```ruby
# Простой диалог создания клиента
def add_client_name(message = nil, *)
  session[:client_name] = name          # Одно значение
  save_context :add_client_key          # Контекст telegram-bot
end

def add_client_key(message = nil, *)
  name = session[:client_name]           # Забираем значение
  client = current_user.clients.create(key: key, name: name)
  session.delete(:client_name)          # Очищаем
end
```

### Примеры из кода

```ruby
# ClientCommand - хороший пример использования session
def handle_add_client
  save_context :add_client_name
  respond_with :message, text: t('telegram.commands.client.add_prompt_name')
end

def add_client_name(message = nil, *)
  session[:client_name] = name
  save_context :add_client_key
  respond_with :message, text: t('telegram.commands.client.add_prompt_key')
end
```

## TelegramSession (высокоуровневая абстракция)

`TelegramSession` - это ORM-подобная обертка над `session` для сложных операций.

### Структура

```ruby
class TelegramSession
  attr_accessor :type, :data

  VALID_TYPES = %i[edit add_user add_time rename].freeze

  def initialize(type, data = {})
    @type = type.to_sym
    @data = data.with_indifferent_access
  end
end
```

### Фабричные методы

```ruby
# Редактирование time_shift
telegram_session = TelegramSession.edit(time_shift_id: 123)

# Добавление пользователя
telegram_session = TelegramSession.add_user(project_slug: 'my-project')

# Добавление времени
telegram_session = TelegramSession.add_time(project_id: 456)

# Переименование
telegram_session = TelegramSession.rename(project_id: 789)
```

### Когда использовать `TelegramSession`

#### ✅ **Сложные многошаговые операции**
```ruby
# Редактирование time_shift с множеством полей
def start_edit
  telegram_session = TelegramSession.edit(time_shift_id: 123)
  telegram_session[:field] = 'hours'
  telegram_session[:new_values] = { hours: 5.5 }
end

def confirm_hours(new_hours)
  telegram_session[:new_values][:hours] = new_hours
  telegram_session[:field] = 'description'
  save_context :edit_description
end

def apply_changes
  if telegram_session.type == :edit
    time_shift = edit_time_shift
    time_shift.update(telegram_session[:new_values])
    clear_telegram_session
  end
end
```

#### ✅ **Операции с валидацией состояния**
```ruby
def process_step
  unless telegram_session.valid?
    respond_with :message, text: 'Ошибка: некорректное состояние операции'
    clear_telegram_session
    return
  end

  # Продолжаем обработку
end
```

#### ✅ **Структурированные данные**
```ruby
# Добавление пользователя с несколькими параметрами
telegram_session = TelegramSession.add_user(project_slug: 'my-project')
telegram_session[:username] = 'john_doe'
telegram_session[:role] = 'member'
telegram_session[:permissions] = ['read', 'write']
```

### Хелперы для работы с TelegramSession

```ruby
# Получить текущую сессию
telegram_session = telegram_session

# Установить сессию
telegram_session = TelegramSession.edit(time_shift_id: 123)
self.telegram_session = telegram_session

# Очистить сессию
clear_telegram_session

# Получить данные сессии
data = telegram_session_data

# Специфичные хелперы
time_shift = edit_time_shift  # только для type == :edit
```

## Сравнительная таблица

| Критерий | `session` | `TelegramSession` |
|---------|-----------|------------------|
| **Сложность данных** | Простые ключ-значения | Структурированные объекты |
| **Количество шагов** | 2-3 шага | 3+ шагов |
| **Валидация** | Нет | Встроенная (`valid?`) |
| **Типизация** | Нет | Есть (`edit`, `add_user`, etc) |
| **Чистота кода** | Много ключей в session | Один объект `telegram_session` |
| **Отладка** | Сложно отслеживать | Легко - одна сущность |
| **Сериализация** | Автоматическая | Ручная (`to_h`/`from_h`) |

## Главное правило

> **Если операция занимает больше 2-3 шагов и имеет структурированные данные → используй `TelegramSession`**
>
> **Если это простой диалог с 1-2 временными значениями → используй `session`**

## Примеры из реального кода

### ClientCommand (использует session)

```ruby
# Простая операция создания клиента - идеально для session
def add_client_name(message = nil, *)
  name = message&.strip
  if name.blank?
    respond_with :message, text: t('telegram.commands.client.name_invalid')
    save_context :add_client_name
    return
  end

  session[:client_name] = name        # Одно значение
  save_context :add_client_key        # Контекст telegram-bot
  respond_with :message, text: t('telegram.commands.client.add_prompt_key')
end

def add_client_key(message = nil, *)
  key = message&.strip&.downcase
  name = session[:client_name]         # Забираем значение

  # Создание клиента...

  session.delete(:client_name)         # Очищаем
end
```

### ResetCommand (показывает очистку обоих типов)

```ruby
def reset_session
  clear_telegram_session        # Очищаем структурированные данные
  reset_session_context         # Очищаем контекст telegram-bot
  telegram_session_keys.each do |key|
    session.delete(key)         # Очищаем простые данные
  end
end

def telegram_session_keys
  session.keys.select do |key|
    key.to_s.start_with?('telegram_') ||
      %w[context edit_client_key client_name edit_project_key].include?(key.to_s)
  end
end
```

## Как это работает внутри

`TelegramSession` не заменяет `session`, а **использует её как хранилище**:

```ruby
# Внутри TelegramSession:
def to_h
  {
    'type' => @type.to_s,
    'data' => @data
  }
end

# Сохраняется как:
session[:telegram_session] = {
  'type' => 'edit',
  'data' => { 'time_shift_id' => 123, 'field' => 'hours' }
}
```

## Лучшие практики

### ✅ **Правильное использование**

```ruby
# Простые данные
session[:temp_value] = user_input

# Контекст telegram-bot
save_context :waiting_for_input

# Сложная операция
telegram_session = TelegramSession.edit(time_shift_id: shift.id)
telegram_session[:step] = :selecting_field
```

### ❌ **Избегать**

```ruby
# Слишком много ключей в session для одной операции
session[:edit_time_shift_id] = 123
session[:edit_field] = 'hours'
session[:edit_new_hours] = 5.5
session[:edit_step] = :confirmation
# ... еще 10 ключей

# Лучше использовать TelegramSession!
```

## Отладка

### Логирование сессий

```ruby
# Для отладки состояния session
Rails.logger.info "Session keys: #{session.keys.inspect}"
Rails.logger.info "Context: #{session[:context]}"
Rails.logger.info "Client name: #{session[:client_name]}"

# Для отладки TelegramSession
Rails.logger.info "Telegram session type: #{telegram_session&.type}"
Rails.logger.info "Telegram session data: #{telegram_session_data.inspect}"
Rails.logger.info "Telegram session valid: #{telegram_session&.valid?}"
```

### Очистка сессий

```ruby
# Полная очистка всех Telegram данных
def reset_all_telegram_data
  clear_telegram_session          # TelegramSession
  reset_session_context           # Контекст telegram-bot

  # Очистка простых ключей
  %w[client_name edit_client_key edit_project_key].each do |key|
    session.delete(key)
  end
end
```

## Примеры из ProjectsCommand

### Правильное использование session для многошаговых операций

ProjectsCommand демонстрирует корректные паттерны работы с `session` для сложных многошаговых операций.

#### Переименование проекта (оба: название и slug)

```ruby
# Шаг 1: Начало операции
def start_rename_both(slug)
  session[:current_project_slug] = slug  # ✅ Данные в session
  save_context :awaiting_rename_both      # ✅ Только имя метода
  respond_with :message, text: t('telegram.commands.projects.rename_both.enter_new_title')
end

# Шаг 2: Получение нового названия
def awaiting_rename_both(*title_parts)
  current_slug = session[:current_project_slug]  # ✅ Чтение
  new_title = title_parts.join(' ')

  session[:new_project_title] = new_title         # ✅ Сохранение
  session[:suggested_slug] = suggested_slug       # ✅ Сохранение
  save_context :awaiting_rename_both_step_2       # ✅ Следующий шаг

  respond_with :message, text: I18n.t('telegram.commands.projects.rename_both.confirm_slug'),
               reply_markup: { inline_keyboard: [...] }
end

# Шаг 3: Получение нового slug и завершение
def awaiting_rename_both_step_2(*slug_parts)
  current_slug = session[:current_project_slug]  # ✅ Чтение
  new_title = session[:new_project_title]         # ✅ Чтение
  new_slug = slug_parts.join('-')

  # ... обработка ...

  # ✅ ОБЯЗАТЕЛЬНО: Очистка после завершения
  session.delete(:current_project_slug)
  session.delete(:new_project_title)
  session.delete(:suggested_slug)
end
```

#### Callback Query с использованием session

```ruby
# Обработчик кнопки "Использовать предложенный slug"
def projects_rename_use_suggested_callback_query(current_slug)
  suggested_slug = session[:suggested_slug]  # ✅ Чтение из session
  new_title = session[:new_project_title]     # ✅ Чтение из session

  project = current_user.memberships.find_by(project: { slug: current_slug })&.project

  if project&.update(title: new_title, slug: suggested_slug)
    respond_with :message, text: I18n.t('telegram.commands.projects.renamed_successfully')
  end

  # ✅ Очистка
  session.delete(:current_project_slug)
  session.delete(:new_project_title)
  session.delete(:suggested_slug)
end
```

#### Создание проекта с несколькими шагами

```ruby
# Шаг 1: Запрос slug для нового проекта
def awaiting_create_slug
  save_context :awaiting_create_slug_input  # ✅ Только контекст
  respond_with :message, text: t('telegram.commands.projects.create.enter_slug')
end

# Шаг 2: Получение slug
def awaiting_create_slug_input(*slug_parts)
  slug = slug_parts.join('-').downcase

  session[:new_project_slug] = slug  # ✅ Сохранение в session
  save_context :awaiting_create_title_input

  respond_with :message, text: t('telegram.commands.projects.create.enter_title')
end

# Шаг 3: Получение title и создание проекта
def awaiting_create_title_input(*title_parts)
  slug = session[:new_project_slug]  # ✅ Чтение из session
  title = title_parts.join(' ')

  project = current_user.projects.create(slug: slug, title: title)

  # ✅ Очистка
  session.delete(:new_project_slug)

  respond_with :message, text: t('telegram.commands.projects.created_successfully')
end
```

### ⚠️ Антипаттерны (НЕ делайте так)

```ruby
# ❌ НЕПРАВИЛЬНО: save_context с данными
save_context(CONTEXT_CURRENT_PROJECT, slug)

# ❌ НЕПРАВИЛЬНО: несуществующий метод from_context
current_slug = from_context(CONTEXT_CURRENT_PROJECT)

# ❌ НЕПРАВИЛЬНО: сохранение данных в константах
CONTEXT_CURRENT_PROJECT = :current_project_slug
save_context(CONTEXT_CURRENT_PROJECT, slug)  # Нет второго аргумента!

# ✅ ПРАВИЛЬНО: session для данных, save_context только для имени метода
session[:current_project_slug] = slug
save_context :awaiting_next_step
current_slug = session[:current_project_slug]
```

### Важные правила из ProjectsCommand

1. **Данные в session, не в save_context**: `session[key] = value`
2. **save_context только для routing**: `save_context :method_name` (БЕЗ второго аргумента!)
3. **Всегда очищайте session**: `session.delete(:key)` после завершения операции
4. **Используйте символы для ключей**: `:current_project_slug`, не строки
5. **Callback query работает с session**: данные должны быть в session, не в callback_data

### Типичные ошибки и их решение

#### ❌ Проблема: Попытка передать данные через save_context
```ruby
# НЕПРАВИЛЬНО
save_context(:awaiting_rename, project_slug)  # save_context не принимает второй аргумент!
```

#### ✅ Решение: Использовать session
```ruby
# ПРАВИЛЬНО
session[:current_project_slug] = project_slug
save_context :awaiting_rename
```

#### ❌ Проблема: Попытка прочитать данные из context
```ruby
# НЕПРАВИЛЬНО
project_slug = from_context(:current_project)  # Метод from_context не существует!
```

#### ✅ Решение: Читать из session
```ruby
# ПРАВИЛЬНО
project_slug = session[:current_project_slug]
```

#### ❌ Проблема: Забыли очистить session
```ruby
# НЕПРАВИЛЬНО - session накапливает мусор
def complete_operation
  # ... делаем работу ...
  respond_with :message, text: 'Готово!'
  # session[:current_project_slug] все еще содержит старые данные!
end
```

#### ✅ Решение: Всегда очищать после завершения
```ruby
# ПРАВИЛЬНО
def complete_operation
  # ... делаем работу ...

  # Очищаем ВСЕ временные данные
  session.delete(:current_project_slug)
  session.delete(:new_project_title)
  session.delete(:suggested_slug)

  respond_with :message, text: 'Готово!'
end
```

## Заключение

Использование правильного типа сессии помогает поддерживать:
- **Чистоту кода** - разделение простых и сложных данных
- **Надежность** - валидация и типизация в TelegramSession
- **Отлаживаемость** - структурированное хранение данных
- **Масштабируемость** - легкое добавление новых полей в TelegramSession

Выбирайте инструмент в соответствии со сложностью операции!