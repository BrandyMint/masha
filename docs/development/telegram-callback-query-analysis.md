# Анализ использования callback_query в проекте Mashtime.ru

**Дата анализа:** 2025-11-15
**Статус:** 🚨 **КРИТИЧЕСКАЯ ПРОБЛЕМА НАЙДЕНА**

## Количество callback_query методов

Общее число методов `*_callback_query` в проекте: **26 штук**

| Файл | Количество | Методы |
|------|-----------|--------|
| `projects_command.rb` | 14 | `projects_create_callback_query`, `projects_select_callback_query`, `projects_list_callback_query`, `projects_rename_callback_query`, `projects_rename_title_callback_query`, `projects_rename_slug_callback_query`, `projects_rename_both_callback_query`, `projects_rename_use_suggested_callback_query`, `projects_client_callback_query`, `projects_client_edit_callback_query`, `projects_client_delete_callback_query`, `projects_client_delete_confirm_callback_query`, `projects_delete_callback_query`, `projects_delete_confirm_callback_query` |
| `report_command.rb` | 5 | `report_periods_callback_query`, `report_filters_callback_query`, `report_options_callback_query`, `report_examples_callback_query`, `report_main_callback_query` |
| `edit_command.rb` | 3 | `edit_field_callback_query`, `edit_project_callback_query`, `edit_confirm_callback_query` |
| `users_command.rb` | 3 | `users_add_project_callback_query`, `users_add_role_callback_query`, `users_list_project_callback_query` |
| `add_command.rb` | 1 | `select_project_callback_query` |

## 🚨 Критическая проблема

**Ни в одном из 26 callback_query методов не вызывается `answer_callback_query()`**

### Что это значит

Когда пользователь нажимает inline-кнопку (например, "✏️ Переименовать", "🗑️ Удалить"):

1. Telegram отправляет `callback_query` запрос боту
2. Бот обрабатывает его через соответствующий `*_callback_query` метод
3. **ПРОБЛЕМА:** Бот не отвечает на `callback_query` с помощью `answer_callback_query()`
4. Кнопка остается в состоянии "загрузки" (часы) в течение 30 секунд
5. Telegram автоматически снимает анимацию через 30 секунд
6. Пользователь не получает никакого визуального подтверждения обработки

### Файлы с проблемой

```ruby
# app/commands/projects_command.rb - 14 методов
# app/commands/report_command.rb - 5 методов
# app/commands/edit_command.rb - 3 метода
# app/commands/users_command.rb - 3 метода
# app/commands/add_command.rb - 1 метод
```

## Конкретные примеры проблемного кода

### Пример 1: `projects_command.rb` - Переименование проекта

```ruby
def projects_rename_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  show_rename_menu(data)  # <- ВЫЗЫВАЕТ respond_with
  # <- НЕТ answer_callback_query() - кнопка зависнет!
end
```

**Что происходит:**
- Пользователь нажимает "✏️ Переименовать"
- Кнопка показывает "часики" загрузки
- Бот отправляет новое меню через `respond_with`
- **НО кнопка продолжает крутить часики 30 секунд!**

**Правильно:**
```ruby
def projects_rename_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  show_rename_menu(data)
  answer_callback_query  # или answer_callback_query('✏️ Переименование...')
end
```

### Пример 2: `report_command.rb` - Навигация по справке

```ruby
def report_periods_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.periods_help
  keyboard = help_formatter.navigation_keyboard('periods')

  edit_message :text, text: text, reply_markup: keyboard
  # <- НЕТ answer_callback_query() - кнопка зависнет!
end
```

**Проблема:** При навигации по справке кнопки "📅 Периоды", "🔍 Фильтры" и т.д. "подвисают".

**Правильно:**
```ruby
def report_periods_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.periods_help
  keyboard = help_formatter.navigation_keyboard('periods')

  edit_message :text, text: text, reply_markup: keyboard
  answer_callback_query  # Просто убрать часики
end
```

### Пример 3: `projects_command.rb` - Подтверждение удаления

```ruby
def projects_delete_confirm_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_delete_confirm_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  request_deletion_confirmation(data)  # <- Вызовет respond_with :message
  # <- НЕТ answer_callback_query() - кнопка зависнет!
end
```

**Правильно:**
```ruby
def projects_delete_confirm_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_delete_confirm_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  request_deletion_confirmation(data)
  answer_callback_query('🚨 Подтверждение удаления...', show_alert: true)
end
```

## Почему это произошло

1. **Модуль `CallbackQueryContext` автоматически маршрутизирует `callback_query`**, но **не автоматически отвечает** на них
2. Разработчики забыли добавить `answer_callback_query()` в каждый метод
3. Нет автоматического `around_action` или `before_action` который бы делал это за них
4. Тесты не проверяют наличие `answer_callback_query` в вызовах

## Как это исправить

### Вариант 1: Ручное добавление (быстрый, но риск ошибок)

В каждый `*_callback_query` метод добавить `answer_callback_query()` в конец:

```ruby
def имя_callback_query(data = nil)
  # ... существующая логика ...
  
  # В конце метода:
  answer_callback_query  # просто убрать часики
  # или
  answer_callback_query('Текст уведомления')
  # или
  answer_callback_query('Важное сообщение', show_alert: true)
end
```

**Плюсы:** Явно, понятно, контроль над текстом уведомления
**Минусы:** 26 мест для ошибки, нужно помнить про каждый новый метод

### Вариант 2: Автоматизация через `around_action` (рекомендуется)

Создать `around_action` в `BaseCommand` или `WebhookController`:

```ruby
# В app/commands/base_command.rb или app/controllers/concerns/telegram/callback_handling.rb

module Telegram
  module CallbackHandling
    extend ActiveSupport::Concern

    included do
      around_action :ensure_callback_answer, if: :callback_query?
    end

    private

    def ensure_callback_answer
      yield  # выполняем основную логику
    ensure
      # Автоматически отвечаем на callback_query, если ещё не ответили
      if callback_query? && !@callback_answered
        answer_callback_query
      end
    end

    def callback_query?
      payload.is_a?(Hash) && payload.key?('callback_query')
    end

    # Переопределяем оригинальный хелпер, чтобы отслеживать ручные вызовы
    def answer_callback_query(text = nil, params = {})
      @callback_answered = true
      super
    end
  end
end
```

И подключить в `WebhookController`:

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::CallbackHandling
  # ...
end
```

**Плюсы:** Работает автоматически, нельзя забыть, покрывает все callback'и
**Минусы:** Менее явно, нужно быть осторожным с `show_alert: true`

### Вариант 3: Гибридный подход (самый лучший)

1. Создать базовый метод в `BaseCommand`:

```ruby
# app/commands/base_command.rb

class BaseCommand
  # ...

  protected

  # Безопасный вызов answer_callback_query с автоматическим запоминанием
  def safe_answer_callback_query(text = nil, params = {})
    @callback_answered = true
    answer_callback_query(text, params) if callback_query_context?
  end

  # Проверяем, обрабатываем ли callback_query
  def callback_query_context?
    controller&.payload&.key?('callback_query')
  end
end
```

2. В каждом `*_callback_query` методе использовать `safe_answer_callback_query`:

```ruby
def projects_rename_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
    safe_answer_callback_query('❌ Ошибка')
    return respond_with :message, text: 'Что-то странное..'
  end
  show_rename_menu(data)
  safe_answer_callback_query
end
```

3. Add `after_action` as safety net:

```ruby
# app/commands/base_command.rb

class BaseCommand
  # ...

  def safe_call(*args)
    Rails.logger.info "#{self.class}.call with args #{args}"

    return respond_with :message, text: I18n.t('telegram.errors.developer_access_denied') if self.class.developer_only? && !developer?

    @callback_answered = false
    result = call(*args)
    ensure_callback_answered
    result
  end

  private

  def ensure_callback_answered
    return unless callback_query_context?
    return if @callback_answered

    # Safety net: auto-answer if forgot
    Rails.logger.warn "Callback query not answered in #{self.class}##{caller_locations.first.label}, auto-answering"
    answer_callback_query
  end
end
```

## Проверка и тестирование

### Добавить тест, который проверяет наличие `answer_callback_query` в callback методах

```ruby
# spec/support/shared_examples/callback_answered_spec.rb

RSpec.shared_examples 'callback query handler' do
  it 'answers callback_query' do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery)
  end
end

# spec/controllers/telegram/webhook/projects_command_spec.rb
RSpec.describe Telegram::WebhookController do
  describe '#projects_rename_callback_query' do
    subject { dispatch(callback_query: { data: "projects_rename:#{project.slug}" }) }
    
    include_examples 'callback query handler'
  end
  
  describe '#projects_list_callback_query' do
    subject { dispatch(callback_query: { data: 'projects_list:' }) }
    
    include_examples 'callback query handler'
  end
end
```

### Чек-лист для миграции

- [ ] Добавить `around_action` или `after_action` в `BaseCommand`
- [ ] Добавить защиту в `safe_call` метод
- [ ] Проверить, что работает в 2-3 командах
- [ ] Добавить тесты на `answer_callback_query` для ключевых callback'ов
- [ ] Создать миграцию для всех 26 методов
- [ ] Протестировать вручную на реальных кнопках

## Срочность

**Высокая!** Пользователи сталкиваются с "зависающими" кнопками постоянно.

### Краткосрочное решение (хотфикс)

Добавить в `WebhookController`:

```ruby
after_action :ensure_callback_answered, if: -> { payload&.key?('callback_query') }

private

def ensure_callback_answered
  # Автоматический ответ на callback_query, если ещё не ответили
  # Предполагаем, что если уже отправили сообщение - callback обработан
  if @callback_answered.nil?
    answer_callback_query
    @callback_answered = true
  end
end
```

Это быстро исправит проблему для всех callback'ов.

### Долгосрочное решение

1. Внедрить гибридный подход (Вариант 3)
2. Добавить тесты
3. Обновить документацию
4. Добавить проверку в CI/CD (линтер, который требует `answer_callback_query` в `*_callback_query`)

## Заключение

Проект **активно использует callback_query** (26 методов), но **не отвечает на них**. Это:

- ❌ Плохой UX (зависшие кнопки на 30 секунд)
- ❌ Потенциальные проблемы с Telegram API
- ❌ Пользователи могут думать, что бот завис

**Нужно немедленно добавить `answer_callback_query` во все callback методы!**
