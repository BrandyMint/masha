# План простого отказа от TelegramSession

## 🎯 **Цель:** Удалить класс TelegramSession, заменив его на простые хеши в Redis session

## 📋 **Текущая ситуация (обновлено):**

### **Сейчас используется:**
- `app/models/telegram_session.rb` с типами `:edit`, `:add_user`, `:add_time`, `:rename`
- `session[:telegram_session]` для хранения сериализованных данных
- Фабричные методы: `TelegramSession.edit`, `TelegramSession.add_user`, etc.
- Методы `save_context` через константы в BaseCommand
- SessionHelpers: `telegram_session`, `telegram_session=`, `telegram_session_data`

### **Ключевые места использования:**
- `app/commands/add_command.rb` - многошаговое добавление времени
- `app/commands/edit_command.rb` - редактирование с `field` и `new_values`
- `app/commands/adduser_command.rb` - добавление пользователей
- `app/commands/rename_command.rb` - переименование проектов
- `app/services/telegram_time_tracker.rb` - парсинг сообщений
- `app/services/telegram/time_shift_operations_service.rb` - операции с time_shift

## 📋 **Что делаем:**

### **Шаг 1: Удаляем TelegramSession**
- Удаляем файл `app/models/telegram_session.rb`
- Удаляем все вызовы `TelegramSession.edit`, `TelegramSession.add_user`, `TelegramSession.add_time`, `TelegramSession.rename`

### **Шаг 2: Заменяем на простые хеши**
```ruby
# Было:
telegram_session = TelegramSession.edit(time_shift_id: 123)
telegram_session[:field] = 'hours'
telegram_session[:new_values] = { hours: 5.5 }

# Стало:
session[:telegram_session] = {
  type: :edit,
  time_shift_id: 123,
  field: 'hours',
  new_values: { hours: 5.5 }
}
```

### **Шаг 3: Обновляем session_helpers.rb**
- `telegram_session` - возвращает `session[:telegram_session] || {}`
- `telegram_session=(data)` - `session[:telegram_session] = data`
- `clear_telegram_session` - `session.delete(:telegram_session)`
- `telegram_session_data` - `session[:telegram_session] || {}`

### **Шаг 4: Обновляем команды**
- **AddCommand**: заменяем `TelegramSession.add_time` на хеш `{ type: :add_time, project_id: id }`
- **EditCommand**: заменяем `TelegramSession.edit` на хеш `{ type: :edit, time_shift_id: id }`
- **AdduserCommand**: заменяем `TelegramSession.add_user` на хеш `{ type: :add_user, project_id: id }`
- **RenameCommand**: заменяем `TelegramSession.rename` на хеш `{ type: :rename, project_id: id }`

### **Шаг 5: Обновляем TimeShiftOperationsService**
- Заменяем `telegram_session[:time_shift_id]` на `session[:telegram_session][:time_shift_id]`
- Сохраняем логику работы с `field` и `new_values`

## ✅ **Результат:**
- Удален один ненужный класс
- Код стал проще и понятнее
- Никаких новых моделей и сложной логики
- Сохраняемся всю функциональность

## ⏱️ **Срок:** 1-2 дня

---

## 🔧 **Детальные изменения (актуально):**

### **Что удаляем:**
- `app/models/telegram_session.rb` - полностью
- Все вызовы `TelegramSession.edit(time_shift_id: id)`
- Все вызовы `TelegramSession.add_user(project_id: id)`
- Все вызовы `TelegramSession.add_time(project_id: id)`
- Все вызовы `TelegramSession.rename(project_id: id)`

### **Что заменяем:**

#### **В EditCommand:**
```ruby
# Было:
telegram_session = TelegramSession.edit(time_shift_id: time_shift.id)
self.telegram_session = telegram_session

# Стало:
session[:telegram_session] = {
  type: :edit,
  time_shift_id: time_shift.id
}
```

#### **В AddCommand:**
```ruby
# Было:
telegram_session = TelegramSession.add_time(project_id: project.id)
self.telegram_session = telegram_session

# Стало:
session[:telegram_session] = {
  type: :add_time,
  project_id: project.id
}
```

#### **В SessionHelpers:**
```ruby
# Было:
def telegram_session
  @telegram_session ||= TelegramSession.from_h(session[:telegram_session] || {})
end

def telegram_session=(tg_session)
  @telegram_session = tg_session
  session[:telegram_session] = tg_session.to_h
end

# Стало:
def telegram_session
  session[:telegram_session] || {}
end

def telegram_session=(data)
  session[:telegram_session] = data
end

def telegram_session_data
  session[:telegram_session] || {}
end
```

#### **В TimeShiftOperationsService:**
```ruby
# Было:
def edit_time_shift
  telegram_session = controller.telegram_session
  time_shift = TimeShift.find(telegram_session[:time_shift_id])
  # ...
end

# Стало:
def edit_time_shift
  session_data = session[:telegram_session]
  time_shift = TimeShift.find(session_data[:time_shift_id])
  # ...
end
```

### **Структуры данных для каждого типа (оставляем как есть):**
```ruby
# edit:
{ type: :edit, time_shift_id: 123, field: 'hours', new_values: { hours: 5.5 } }

# add_user:
{ type: :add_user, project_id: 456, username: 'user123', role: 'member' }

# add_time:
{ type: :add_time, project_id: 456 }

# rename:
{ type: :rename, project_id: 456, new_name: 'New Project Name' }
```

## 📝 **Порядок миграции (актуально):**

1. **Обновляем SessionHelpers** - упрощаем методы работы с сессией
2. **Обновляем EditCommand** - заменяем `TelegramSession.edit` на хеш
3. **Обновляем AddCommand** - заменяем `TelegramSession.add_time` на хеш
4. **Обновляем AdduserCommand** - заменяем `TelegramSession.add_user` на хеш
5. **Обновляем RenameCommand** - заменяем `TelegramSession.rename` на хеш
6. **Обновляем TimeShiftOperationsService** - работаем напрямую с `session[:telegram_session]`
7. **Удаляем** `app/models/telegram_session.rb`
8. **Запускаем тесты** и проверяем что ничего не сломалось

## 🧪 **Тестирование:**

- Проверяем что все многошаговые команды (/edit, /add, /adduser, /rename) работают как раньше
- Проверяем что команды с параметрами (/add project 2 work) продолжают работать
- Проверяем что TelegramTimeTracker парсинг сообщений работает
- Проверяем что сессии не смешиваются между пользователями
- Проверяем обработку ошибок и очистку сессий
- Запускаем RSpec тесты в `spec/controllers/telegram/webhook/`