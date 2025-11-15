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

#### ProjectsCommand - многошаговые операции с session

```ruby
# Пример: Переименование проекта (только slug)
# 1. Callback устанавливает контекст
def projects_rename_slug_callback_query(data = nil)
  project = current_user.projects.find_by(slug: data)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  session[:current_project_slug] = data  # Сохраняем текущий slug
  save_context CONTEXT_AWAITING_RENAME_SLUG  # Устанавливаем контекст

  respond_with :message, text: t('commands.projects.rename.enter_slug', current_slug: project.slug)
end

# 2. Context method обрабатывает ввод
def awaiting_rename_slug(*slug_parts)
  new_slug = slug_parts.join(' ').strip
  return handle_cancel_input :rename_slug if cancel_input?(new_slug)

  # Получаем сохраненный slug из session
  current_slug = session[:current_project_slug]
  project = current_user.projects.find_by(slug: current_slug)
  return show_projects_list unless project

  # Валидация
  return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(new_slug)

  if Project.where.not(id: project.id).exists?(slug: new_slug)
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: new_slug)
  end

  # Обновление и очистка
  if project.update(slug: new_slug)
    session.delete(:current_project_slug)  # ⚠️ Важно: очищаем session
    respond_with :message, text: t('commands.projects.rename.success_slug', old_slug: current_slug, new_slug: new_slug)
    return show_project_menu(new_slug)  # ⚠️ Важно: return для правильного ответа
  else
    return respond_with :message, text: t('commands.projects.rename.error')
  end
end
```

**Ключевые моменты из ProjectsCommand:**

1. **Константы для контекстов** - используются вместо magic strings:
   ```ruby
   CONTEXT_AWAITING_RENAME_SLUG = :awaiting_rename_slug
   save_context CONTEXT_AWAITING_RENAME_SLUG  # Не 'awaiting_rename_slug'
   ```

2. **Регистрация context methods** в provides_context_methods:
   ```ruby
   provides_context_methods(
     :awaiting_rename_slug,
     :awaiting_rename_both,
     :awaiting_client_name
   )
   ```

3. **Очистка session** после завершения операции:
   ```ruby
   session.delete(:current_project_slug)
   session.delete(:new_project_title)
   session.delete(:suggested_slug)
   ```

4. **return для respond_with** во всех ветках:
   ```ruby
   # ✅ Правильно
   return respond_with :message, text: 'Ошибка'

   # ❌ Неправильно - ответ не вернется
   respond_with :message, text: 'Ошибка'
   return
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

## Заключение

Использование правильного типа сессии помогает поддерживать:
- **Чистоту кода** - разделение простых и сложных данных
- **Надежность** - валидация и типизация в TelegramSession
- **Отлаживаемость** - структурированное хранение данных
- **Масштабируемость** - легкое добавление новых полей в TelegramSession

Выбирайте инструмент в соответствии со сложностью операции!