# План рефакторинга ReportCommand

## Цель
Устранить нарушения правил работы с callback query согласно `docs/development/telegram-callback-guide.md`

## Обнаруженные нарушения

### 1. Ручной разбор callback_data в ReportCommand
**Файл:** `app/commands/report_command.rb:117-131`

```ruby
# ❌ НАРУШЕНИЕ
def report_callback_query(data = nil)
  data ||= callback_data
  return unless data&.start_with?('report_help_')  # Ручной разбор

  section = data.sub('report_help_', '')           # Извлечение через sub
  return unless HELP_SECTIONS.key?(section)

  help_formatter = ReportHelpFormatter.new
  text = help_formatter.send(HELP_SECTIONS[section])
  keyboard = help_formatter.navigation_keyboard(section)

  edit_message :text, text: text, reply_markup: keyboard
end
```

### 2. Множественные разделители в callback_data
**Файл:** `app/services/report_help_formatter.rb`

```ruby
# ❌ НАРУШЕНИЕ - два подчеркивания
callback_data: 'report_help_periods'   # должно быть 'report_periods'
callback_data: 'report_help_filters'   # должно быть 'report_filters'
callback_data: 'report_help_options'   # должно быть 'report_options'
callback_data: 'report_help_examples'  # должно быть 'report_examples'
callback_data: 'report_help_main'      # должно быть 'report_main'
```

## Этапы рефакторинга

### Этап 1: Анализ текущей реализации ✅

**Результаты анализа:**

Найдены все места использования callback_data:

1. **ReportHelpFormatter** (`app/services/report_help_formatter.rb`):
   - `main_keyboard()` - строки 41-42, 46
   - `base_navigation_buttons()` - строка 162
   - `section_buttons()` - строки 173-176

2. **ReportCommand** (`app/commands/report_command.rb`):
   - `report_callback_query()` - метод с нарушениями (строки 117-131)

3. **Тесты**:
   - `spec/services/report_help_formatter_spec.rb` - проверяет callback_data
   - `spec/controllers/telegram/webhook/report_command_spec.rb` - проверяет callback query

### Этап 2: Изменение ReportCommand

**Действия:**

1. Удалить метод `report_callback_query` (строки 117-131)
2. Удалить константу `HELP_SECTIONS` (строки 13-19)
3. Удалить метод `callback_data` (строки 133-136)

4. Создать 5 отдельных callback методов:

```ruby
# ✅ ПРАВИЛЬНАЯ РЕАЛИЗАЦИЯ
def report_periods_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.periods_help
  keyboard = help_formatter.navigation_keyboard('periods')

  edit_message :text, text: text, reply_markup: keyboard
end

def report_filters_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.filters_help
  keyboard = help_formatter.navigation_keyboard('filters')

  edit_message :text, text: text, reply_markup: keyboard
end

def report_options_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.options_help
  keyboard = help_formatter.navigation_keyboard('options')

  edit_message :text, text: text, reply_markup: keyboard
end

def report_examples_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.examples_help
  keyboard = help_formatter.navigation_keyboard('examples')

  edit_message :text, text: text, reply_markup: keyboard
end

def report_main_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.main_help
  keyboard = help_formatter.main_keyboard

  edit_message :text, text: text, reply_markup: keyboard
end
```

### Этап 3: Изменение ReportHelpFormatter

**Действия:**

Обновить все `callback_data` с `report_help_*` на `report_*`:

1. В методе `main_keyboard()` (строки 41-42, 46):
```ruby
# Было:
{ text: '📅 Периоды', callback_data: 'report_help_periods' },
{ text: '🔍 Фильтры', callback_data: 'report_help_filters' },
{ text: '⚙️ Опции', callback_data: 'report_help_options' },
{ text: '💡 Примеры', callback_data: 'report_help_examples' }

# Станет:
{ text: '📅 Периоды', callback_data: 'report_periods' },
{ text: '🔍 Фильтры', callback_data: 'report_filters' },
{ text: '⚙️ Опции', callback_data: 'report_options' },
{ text: '💡 Примеры', callback_data: 'report_examples' }
```

2. В методе `base_navigation_buttons()` (строка 162):
```ruby
# Было:
buttons << [{ text: '◀️ Назад', callback_data: 'report_help_main' }]

# Станет:
buttons << [{ text: '◀️ Назад', callback_data: 'report_main' }]
```

3. В методе `section_buttons()` (строки 173-176):
```ruby
# Было:
sections = {
  'periods' => { text: '📅 Периоды', callback_data: 'report_help_periods' },
  'filters' => { text: '🔍 Фильтры', callback_data: 'report_help_filters' },
  'options' => { text: '⚙️ Опции', callback_data: 'report_help_options' },
  'examples' => { text: '💡 Примеры', callback_data: 'report_help_examples' }
}

# Станет:
sections = {
  'periods' => { text: '📅 Периоды', callback_data: 'report_periods' },
  'filters' => { text: '🔍 Фильтры', callback_data: 'report_filters' },
  'options' => { text: '⚙️ Опции', callback_data: 'report_options' },
  'examples' => { text: '💡 Примеры', callback_data: 'report_examples' }
}
```

### Этап 4: Обновление тестов ReportHelpFormatter

**Файл:** `spec/services/report_help_formatter_spec.rb`

**Действия:**

Обновить ожидаемые значения `callback_data`:

1. Тест `main_keyboard` - периоды (строки 62-68):
```ruby
# Было:
expect(periods_button[:callback_data]).to eq('report_help_periods')

# Станет:
expect(periods_button[:callback_data]).to eq('report_periods')
```

2. Тест `main_keyboard` - фильтры (строки 70-76):
```ruby
# Было:
expect(filters_button[:callback_data]).to eq('report_help_filters')

# Станет:
expect(filters_button[:callback_data]).to eq('report_filters')
```

3. Тест `main_keyboard` - опции (строки 78-84):
```ruby
# Было:
expect(options_button[:callback_data]).to eq('report_help_options')

# Станет:
expect(options_button[:callback_data]).to eq('report_options')
```

4. Тест `main_keyboard` - примеры (строки 86-92):
```ruby
# Было:
expect(examples_button[:callback_data]).to eq('report_help_examples')

# Станет:
expect(examples_button[:callback_data]).to eq('report_examples')
```

5. Тест `navigation_keyboard` - кнопка "Назад" (строки 191-199):
```ruby
# Было:
expect(back_button[:callback_data]).to eq('report_help_main')

# Станет:
expect(back_button[:callback_data]).to eq('report_main')
```

### Этап 5: Обновление тестов ReportCommand

**Файл:** `spec/controllers/telegram/webhook/report_command_spec.rb`

**Действия:**

Обновить все `callback_data` в тестах callback query (строки 145-239):

1. Периоды (строка 150):
```ruby
# Было:
let(:data) { 'report_help_periods' }

# Станет:
let(:data) { 'report_periods' }
```

2. Фильтры (строка 165):
```ruby
# Было:
let(:data) { 'report_help_filters' }

# Станет:
let(:data) { 'report_filters' }
```

3. Опции (строка 180):
```ruby
# Было:
let(:data) { 'report_help_options' }

# Станет:
let(:data) { 'report_options' }
```

4. Примеры (строка 195):
```ruby
# Было:
let(:data) { 'report_help_examples' }

# Станет:
let(:data) { 'report_examples' }
```

5. Назад к главной (строка 210):
```ruby
# Было:
let(:data) { 'report_help_main' }

# Станет:
let(:data) { 'report_main' }
```

### Этап 6: Проверка работоспособности

**Команды для тестирования:**

```bash
# 1. Запустить тесты ReportHelpFormatter
bundle exec rspec spec/services/report_help_formatter_spec.rb

# 2. Запустить тесты ReportCommand (unit)
bundle exec rspec spec/commands/report_command_spec.rb

# 3. Запустить тесты ReportCommand (webhook controller)
bundle exec rspec spec/controllers/telegram/webhook/report_command_spec.rb

# 4. Запустить все тесты связанные с report
bundle exec rspec spec --pattern="**/*report*"
```

**Критерии успеха:**
- ✅ Все тесты проходят
- ✅ Нет нарушений правил callback query
- ✅ Каждый callback обрабатывается отдельным методом
- ✅ Максимум один разделитель в `callback_data`
- ✅ Отсутствует ручной разбор через `start_with?`, `sub`, `case/when`

## Сводная таблица изменений

| Старый callback_data | Новый callback_data | Метод обработки |
|---------------------|---------------------|-----------------|
| `report_help_periods` | `report_periods` | `report_periods_callback_query` |
| `report_help_filters` | `report_filters` | `report_filters_callback_query` |
| `report_help_options` | `report_options` | `report_options_callback_query` |
| `report_help_examples` | `report_examples` | `report_examples_callback_query` |
| `report_help_main` | `report_main` | `report_main_callback_query` |

## Затронутые файлы

### Код (3 файла)
1. ✏️ `app/commands/report_command.rb` - удалить 1 метод, добавить 5 методов
2. ✏️ `app/services/report_help_formatter.rb` - обновить callback_data (5 мест)

### Тесты (2 файла)
3. ✏️ `spec/services/report_help_formatter_spec.rb` - обновить ожидаемые значения (5 тестов)
4. ✏️ `spec/controllers/telegram/webhook/report_command_spec.rb` - обновить callback_data (5 контекстов)

## Риски и предосторожности

### Минимальные риски
- ✅ Изменения полностью обратно совместимы (не ломают существующую функциональность)
- ✅ Все тесты покрывают изменяемую функциональность
- ✅ Нет изменений в бизнес-логике, только структура callback обработки

### Рекомендации
1. Выполнять изменения последовательно по этапам
2. Запускать тесты после каждого этапа
3. Использовать git для отслеживания изменений (можно откатить любой этап)

## Примечания

### Почему это важно исправить?

1. **Соблюдение convention**: Telegram-бот gem автоматически маршрутизирует callback по префиксу
2. **Читаемость**: 5 методов по 6-8 строк читабельнее 1 метода на 15 строк с условиями
3. **Поддержка**: Добавление нового раздела справки = просто добавить новый метод
4. **Тестирование**: Каждый callback легко тестировать независимо

### Эталонные команды для reference

После рефакторинга ReportCommand будет соответствовать эталонам:
- ✅ ProjectsCommand (14 callback методов)
- ✅ EditCommand (3 callback метода)
- ✅ UsersCommand (3 callback метода)
- ✅ AddCommand (1 callback метод)

## Чеклист выполнения

- [ ] Этап 1: Анализ (✅ Завершен)
- [ ] Этап 2: Изменение ReportCommand
- [ ] Этап 3: Изменение ReportHelpFormatter
- [ ] Этап 4: Обновление тестов ReportHelpFormatter
- [ ] Этап 5: Обновление тестов ReportCommand
- [ ] Этап 6: Проверка работоспособности
- [ ] Финальная проверка: Code review изменений
- [ ] Commit и push изменений
