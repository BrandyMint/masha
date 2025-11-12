# План простого отказа от TelegramSession

## 🎯 **Цель:** Удалить класс TelegramSession, заменив его на простые хеши в Redis session

## 📋 **Что делаем:**

### **Шаг 1: Удаляем TelegramSession**
- Удаляем файл `app/models/telegram_session.rb`
- Удаляем все вызовы `TelegramSession.edit`, `TelegramSession.add_user`, etc.

### **Шаг 2: Заменяем на простые хеши**
```ruby
# Было:
telegram_session = TelegramSession.edit(time_shift_id: 123)
telegram_session[:field] = 'hours'

# Стало:
session[:telegram_state] = {
  type: :edit,
  time_shift_id: 123,
  field: 'hours'
}
```

### **Шаг 3: Обновляем методы (без save_context)**
- `save_context` → `save_state_context` (оставляем старый для обратной совместимости)
- `load_context` → `load_state_context`
- `clear_context` → `clear_state_context`

### **Шаг 4: Обновляем команды**
- AddCommand: заменяем TelegramSession.add_time на хеш
- EditCommand: заменяем TelegramSession.edit на хеш
- AdduserCommand: заменяем TelegramSession.add_user на хеш
- RenameCommand: заменяем TelegramSession.rename на хеш

### **Шаг 5: Обновляем хелперы**
- `telegram_session=` → прямой work с `session[:telegram_state]`
- `telegram_session_data` → `session[:telegram_state]`

## ✅ **Результат:**
- Удален один ненужный класс
- Код стал проще и понятнее
- Никаких новых моделей и сложной логики
- Сохраняемся всю функциональность

## ⏱️ **Срок:** 1-2 дня

---

## 🔧 **Детальные изменения:**

### **Что удаляем:**
- `app/models/telegram_session.rb` - полностью
- Все вызовы `TelegramSession.edit`, `TelegramSession.add_user`, `TelegramSession.add_time`, `TelegramSession.rename`

### **Что заменяем:**

#### **В command классах:**
```ruby
# Было:
def save_edit_context(time_shift)
  telegram_session = TelegramSession.edit(time_shift_id: time_shift.id)
  self.telegram_session = telegram_session
end

# Стало:
def save_edit_context(time_shift)
  session[:telegram_state] = {
    type: :edit,
    time_shift_id: time_shift.id,
    step: :select_field
  }
end
```

#### **В controller:**
```ruby
# Было:
def telegram_session_data
  telegram_session.to_h
end

# Стало:
def telegram_session_data
  session[:telegram_state] || {}
end
```

#### **В telegram_time_tracker.rb:**
```ruby
# Было:
def process_with_session
  session_data = controller.telegram_session_data
  # ...
end

# Стало:
def process_with_session
  session_data = session[:telegram_state] || {}
  # ...
end
```

### **Новые методы для работы с состоянием:**
```ruby
# В контроллере или concerns:
def save_state_context(type, data)
  session[:telegram_state] = data.merge(type: type)
end

def load_state_context
  session[:telegram_state] || {}
end

def clear_state_context
  session.delete(:telegram_state)
end
```

### **Типы состояний:**
- `:edit` - редактирование time_shift
- `:add_user` - добавление пользователя
- `:add_time` - быстрое добавление времени
- `:rename` - переименование проекта

### **Структура данных для каждого типа:**
```ruby
# edit:
{ type: :edit, time_shift_id: 123, field: 'hours', new_values: { hours: 5.5 } }

# add_user:
{ type: :add_user, project_id: 456, step: 'select_user' }

# add_time:
{ type: :add_time, project_id: 456, step: 'input_time' }

# rename:
{ type: :rename, project_id: 456, step: 'input_name' }
```

## 📝 **Порядок миграции:**

1. **Добавляем новые методы** `save_state_context`, `load_state_context`, `clear_state_context`
2. **Обновляем одну команду** (например, EditCommand) для работы с новым подходом
3. **Тестируем** обновленную команду
4. **Повторяем** для остальных команд
5. **Удаляем** `app/models/telegram_session.rb`
6. **Очищаем** неиспользуемые методы

## 🧪 **Тестирование:**

- Проверяем что все многошаговые команды работают как раньше
- Проверяем что сессии не смешиваются между пользователями
- Проверяем что старые команды с параметрами продолжают работать
- Проверяем обработку ошибок и очистку сессий