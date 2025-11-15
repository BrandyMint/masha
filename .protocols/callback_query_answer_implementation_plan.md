# План внедрения answer_callback_query в проект Mashtime.ru

**Дата создания:** 2025-11-15
**Автор:** AI Assistant
**Тип:** План внедрения
**Статус:** Черновик
**Приоритет:** Критический (High Priority)

---

## 1. Обзор проблемы

### Текущее состояние
- В проекте **26 callback_query методов** в файлах `app/commands/*`
  - `projects_command.rb`: 14 методов
  - `report_command.rb`: 5 методов
  - `edit_command.rb`: 3 метода
  - `users_command.rb`: 3 метода
  - `add_command.rb`: 1 метод
- **Ни в одном методе не вызывается `answer_callback_query()`**

### Последствия
- Когда пользователь нажимает inline-кнопку, она показывает "часики" загрузки в течение **30 секунд**
- Пользователь не получает визуального подтверждения нажатия
- Плохой UX, бот кажется медленным/неотзывчивым
- Потенциальные проблемы с Telegram API (обработка повторных нажатий)

### Цели плана
1. ✅ Двухуровневая защита: автоматический ответ + ручное добавление
2. ✅ Постепенная миграция: от безопасной автоматики к явным вызовам
3. ✅ Тестовое покрытие: убедиться, что все callback'и отвечают
4. ✅ Минимальные риски: откатываемые изменения, безопасный релиз

---

## 2. Этап 1: Реализация автоматического ответа (Safety Net)

### 2.1. Добавление безопасности в BaseCommand

**Расположение:** `app/commands/base_command.rb`

```ruby
class BaseCommand
  # frozen_string_literal: true
  include FormatHelpers

  NOTIFY_MESSAGE_INPUT = :notify_message_input

  # ... (существующие константы) ...

  # НОВОЕ: Флаг отслеживания ответа на callback
  attr_accessor :callback_answered

  def safe_call(*args)
    Rails.logger.info "#{self.class}.call with args #{args}"

    # Автоматическая проверка для developer_only команд
    return respond_with :message, text: I18n.t('telegram.errors.developer_access_denied') if self.class.developer_only? && !developer?

    # Инициализация флага для safety net
    @callback_answered = false

    result = call(*args)

    # После выполнения команды - проверяем и автоматически отвечаем
    ensure_callback_answered

    result
  rescue StandardError => e
    # Гарантированный ответ на callback при ошибке
    auto_answer_callback_query if in_callback_context? && !@callback_answered
    raise
  end

  # ... (существующие методы) ...

  protected

  # НОВОЕ: Метод для безопасного вызова answer_callback_query с отслеживанием
  def safe_answer_callback_query(text = )
    return unless in_callback_context?
    answer_callback_query text
  rescue StandardError => e
    Rails.logger.error "Failed to answer callback query: #{e.message}"
    Bugsnag.notify(e)
  end

  # НОВОЕ: Метод для автоматического ответа (safety net)
  def auto_answer_callback_query
    answer_callback_query( '✅' )
  rescue StandardError => e
    Rails.logger.error "Failed auto-answer callback query: #{e.message}"
    Bugsnag.notify(e)
  end

  private

  def answer_callback_query(text - nil)
    @callback_answered = true
    controller.answer_callback_query text
  end

  # НОВОЕ: Проверка контекста
  def in_callback_context?
    controller.payload.key?('callback_query')
  end

  # НОВОЕ: Safety net - гарантированный ответ на callback
  def ensure_callback_answered
    return unless in_callback_context?
    return if @callback_answered

    Rails.logger.warn "Callback query not manually answered in #{self.class}##{caller_locations(2, 1).first.label}, auto-answering"
    auto_answer_callback_query
  end

end
```

### 2.2. Обновление делегата в BaseCommand

```ruby
delegate :developer?, :respond_with, :edit_message,
         :chat, :telegram_user, :t, :bot, to: :controller, allow_nil: true
delegate :find_project, to: :current_user

```

### 2.3. Тестирование этапа 1

**Тест 1: Базовый safety net**
```ruby
# spec/commands/base_command_spec.rb

RSpec.describe BaseCommand, type: :model do
  let(:controller) { double('controller', payload: { 'callback_query' => { 'id' => '123' } }) }
  let(:command) { TestCommand.new(controller) }
  let(:bot) { double('bot') }

  before do
    allow(controller).to receive(:bot).and_return(bot)
    allow(bot).to receive(:answer_callback_query)
  end

  it 'automatically answers callback query if not answered manually' do
    expect(bot).to receive(:answer_callback_query)

    command.safe_call
  end

  it 'tracks manual answer_callback_query calls' do
    allow(command).to receive(:call) { command.safe_answer_callback_query('Manual answer') }
    
    expect(bot).to receive(:answer_callback_query).with('Manual answer')
    expect(bot).not_to receive(:answer_callback_query).with('✅')

    command.safe_call
  end
end
```

**Критерий успеха:** Все существующие callback-методы начнут автоматически отвечать, даже без изменения кода

---

## 3. Этап 2: Ручное добавление answer_callback_query в каждый метод

### 3.1. Стратегия миграции

**Порядок миграции (по использованию):**
1. `report_command.rb` (5 методов, самые простые)
2. `add_command.rb` (1 метод)
3. `users_command.rb` (3 метода)
4. `edit_command.rb` (3 метода)
5. `projects_command.rb` (14 методов, самые сложные)

**Каждый метод модифицируем по шаблону:**

### 3.2. Типовые случаи и шаблоны

#### Шаблон 1: Простая навигация (без ошибок)
**До:**
```ruby
def report_periods_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.periods_help
  keyboard = help_formatter.navigation_keyboard('periods')

  edit_message :text, text: text, reply_markup: keyboard
end
```

**После:**
```ruby
def report_periods_callback_query
  help_formatter = ReportHelpFormatter.new
  text = help_formatter.periods_help
  keyboard = help_formatter.navigation_keyboard('periods')

  edit_message :text, text: text, reply_markup: keyboard
  safe_answer_callback_query  # Просто убрать часики
end
```

#### Шаблон 2: Операция с возможной ошибкой
**До:**
```ruby
def projects_rename_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  show_rename_menu(data)
end
```

**После:**
```ruby
def projects_rename_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_rename_callback_query called without data'))
    safe_answer_callback_query('❌ Ошибка: Нет данных')
    return respond_with :message, text: 'Что-то странное..'
  end
  show_rename_menu(data)
  safe_answer_callback_query('✏️ Открыто меню переименования')
end
```

#### Шаблон 3: Подтверждение действия с alert
**До:**
```ruby
def projects_delete_confirm_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_delete_confirm_callback_query called without data'))
    return respond_with :message, text: 'Что-то странное..'
  end
  request_deletion_confirmation(data)
end
```

**После:**
```ruby
def projects_delete_confirm_callback_query(data = nil)
  unless data
    Bugsnag.notify(RuntimeError.new('projects_delete_confirm_callback_query called without data'))
    safe_answer_callback_query('❌ Ошибка', show_alert: true)
    return respond_with :message, text: 'Что-то странное..'
  end
  request_deletion_confirmation(data)
  safe_answer_callback_query('⚠️ Запрошено подтверждение удаления')
end
```

### 3.3. Поэтапная миграция файлов

#### Этап 2.1: report_command.rb (5 методов, 30 минут)

**Шаги:**
1. Открыть `app/commands/report_command.rb`
2. Найти 5 `*_callback_query` методов (строки 111-149)
3. Добавить `safe_answer_callback_query` в конец каждого
4. Запуск тестов: `bundle exec rspec spec/controllers/telegram/webhook/report_command_spec.rb`
5. Мануальное тестирование: `/report help` и клики по кнопкам справки

**Безопасность:**
- Все методы вызывают `edit_message` - безопасно добавлять в конец
- Если ошибка, safety net из этапа 1 сработает перед исключением

#### Этап 2.2: add_command.rb (1 метод, 10 минут)

**Шаги:**
1. Открыть `app/commands/add_command.rb`
2. Найти `select_project_callback_query` (строка ~19)
3. Добавить `safe_answer_callback_query` после обработки
4. Запуск связанных тестов

#### Этап 2.3: users_command.rb (3 метода, 40 минут)

**Шаги:**
1. Открыть `app/commands/users_command.rb`
2. Найти 3 `*_callback_query` метода (строки 159-191)
3. Добавить `safe_answer_callback_query` в каждый
4. Добавить персонализированные сообщения:
   - `users_add_project_callback_query`: `'✅ Проект выбран'`
   - `users_add_role_callback_query`: `'✅ Роль выбрана'`
   - `users_list_project_callback_query`: `'📋 Список пользователей'`
5. Запуск тестов

#### Этап 2.4: edit_command.rb (3 метода, 40 минут)

**Шаги:**
1. Открыть `app/commands/edit_command.rb`
2. Найти 3 метода (строки 59-67)
3. Добавить `safe_answer_callback_query` с контекстом
4. Добавить обработку ошибок в начале каждого метода

#### Этап 2.5: projects_command.rb (14 методов, 2 часа)

**Шаги (подэтапы):**

**Подэтап 2.5.1: Навигационные методы (5 методов, 30 минут)**
- `projects_create_callback_query`
- `projects_select_callback_query`
- `projects_list_callback_query`
- `projects_rename_callback_query`
- `projects_client_callback_query`

**Подэтап 2.5.2: Редактирование проекта (6 методов, 50 минут)**
- `projects_rename_title_callback_query`
- `projects_rename_slug_callback_query`
- `projects_rename_both_callback_query`
- `projects_rename_use_suggested_callback_query`
- `projects_client_edit_callback_query`
- `projects_client_delete_callback_query`

**Подэтап 2.5.3: Удаление проекта и клиента (3 метода, 40 минут)**
- `projects_client_delete_confirm_callback_query`
- `projects_delete_callback_query`
- `projects_delete_confirm_callback_query`

**Важно:** В методах удаления использовать `show_alert: true` для критических действий

### 3.4. Общий чек-лист для каждого файла

- [ ] Все методы `*_callback_query` найдены
- [ ] В начале каждого метода: проверка `data` с `safe_answer_callback_query('❌ Ошибка')` при ошибке
- [ ] В конце каждого "happy path": `safe_answer_callback_query('✅/📋/...')`
- [ ] Для критических действий (удаление): `show_alert: true`
- [ ] Сообщения локализованы (если нужно)
- [ ] Тесты проходят
- [ ] Мануальное тестирование UI

---

## 4. Этап 3: Тестирование и валидация

### 4.1. Добавление тестов на callback ответы

**Общий shared example:**
```ruby
# spec/support/shared_examples/telegram_callback_responses.rb

RSpec.shared_examples 'callback query responder' do
  it 'answers callback query' do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery)
  end
end

RSpec.shared_examples 'callback query with message' do |message_part|
  it "answers callback query with message containing '#{message_part}'" do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery).with(
      hash_including(text: match(/#{message_part}/))
    )
  end
end
```

### 4.2. Тесты для каждой команды

#### Для report_command
```ruby
# spec/controllers/telegram/webhook/report_command_spec.rb

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  describe 'callback queries' do
    describe '#report_periods_callback_query' do
      let(:data) { 'report_periods:' }
      subject { dispatch(callback_query: { data: data }) }

      include_examples 'callback query responder'
      include_examples 'callback query with message', 'период'
    end

    describe '#report_filters_callback_query' do
      let(:data) { 'report_filters:' }
      subject { dispatch(callback_query: { data: data }) }

      include_examples 'callback query responder'
      include_examples 'callback query with message', 'фильтр'
    end

    # ... остальные 3 метода
  end
end
```

#### Для projects_command (сложнее)
```ruby
# spec/controllers/telegram/webhook/projects_command_spec.rb

RSpec.describe Telegram::WebhookController, telegram_bot: :rails do
  let(:user) { users(:user_with_telegram) }
  let(:project) { projects(:existing_project) }

  describe 'projects callback queries' do
    describe '#projects_rename_callback_query' do
      let(:data) { "projects_rename:#{project.slug}" }
      subject { dispatch(callback_query: { data: data }) }

      include_examples 'callback query responder'
      include_examples 'callback query with message', 'переименование'
    end

    describe '#projects_delete_confirm_callback_query' do
      let(:data) { "projects_delete_confirm:#{project.slug}" }
      subject { dispatch(callback_query: { data: data }) }

      it 'answers with alert' do
        expect { subject }.to make_telegram_request(bot, :answerCallbackQuery).with(
          hash_including(show_alert: true)
        )
      end
    end

    # ... остальные 12 методов
  end
end
```

### 4.3. Интеграционные тесты

**Тест полного цикла:**
```ruby
# spec/features/telegram_callback_flow_spec.rb

RSpec.feature 'Telegram callback query flow', telegram_bot: :rails do
  scenario 'user navigates through project menu without hanging buttons' do
    # 1. User calls /projects
    response = dispatch_command :projects
    expect(response).to be_present

    # 2. User clicks on project
    response = dispatch(callback_query: {
      data: "projects_select:#{project.slug}",
      message: response.first
    })
    expect(response).to be_present
    expect(bot.requests[:answerCallbackQuery]).to be_present

    # 3. User clicks rename
    response = dispatch(callback_query: {
      data: "projects_rename:#{project.slug}",
      message: response.first
    })
    expect(response).to be_present
    expect(bot.requests[:answerCallbackQuery]).to be_present

    # 4. Verify button doesn't hang (no duplicate answerCallbackQuery after 30s)
    expect(bot.requests[:answerCallbackQuery].count).to eq(2)
  end
end
```

### 4.4. Мануальное тестирование

**Тест-чеклист для ручного тестирования:**

- [ ] **/projects** → клик по проекту → клик "Переименовать" → часики исчезают моментально
- [ ] **/report help** → клик по "📅 Периоды" → клик по "🔍 Фильтры" → никаких задержек
- [ ] **/edit** → выбор времени → клик по полю → изменение сохраняется без подвисания
- [ ] **/users** → добавление пользователя → выбор проекта → клик работает мгновенно
- [ ] **/projects** → удаление проекта → подтверждение → показывается alert и затем убирается
- [ ] **Повторное быстрое нажатие** → кнопка не обрабатывается дважды (Telegram блокирует)

---

## 5. Релиз и деплой

### 5.1. Порядок релиза

**Этап 1 (Немедленно):**
```bash
# В личной ветке
1. Добавить BaseCommand изменения (safety net)
2. Протестировать на локальной машине с реальным ботом
3. Сделать PR с только safety net изменениями
4. Задеплоить в production
```

**Этап 2 (Через 1-2 дня, после мониторинга):**
```bash
# В отдельной ветке для каждой команды (или одной ветке)
1. report_command (5 методов)
2. add_command (1 метод)
3. users_command (3 метода)
4. edit_command (3 метода)
5. projects_command (14 методов)

# Каждый PR включает:
- Изменения в команде
- Тесты для этих изменений
- Обновленная документация (если нужно)
```

### 5.2. Мониторинг после релиза

**Что мониторить:**
- [ ] Частота вызовов `answerCallbackQuery` (должна вырасти)
- [ ] Время ответа callback (должно завершаться за <1 секунду)
- [ ] Количество "зависших" кнопок (должно упасть до 0)
- [ ] Пользовательские жалобы в Telegram
- [ ] Ошибки в Bugsnag на вызовы `answerCallbackQuery`

**KPI до/после:**
```
До: 0 answerCallbackQuery в минуту
После (Этап 1): ~50-100 answerCallbackQuery в минуту (автоматические)
После (Этап 2): ~50-100 answerCallbackQuery в минуту (явные)
```

### 5.3. Rollback план

**Откат Этапа 1 (Safety Net):**
```bash
# Просто откатить коммит в BaseCommand
git revert <commit-hash>
# Или откатить PR в GitHub
# Никаких side effects нет, т.к. это только добавление безопасности
```

**Откат Этапа 2 (Ручные изменения):**
```bash
# Для каждого файла:
git revert <commit-hash>

# Альтернатива: быстрый патч - удалить все `safe_answer_callback_query` вызовы
find app/commands -name "*.rb" -exec sed -i '/safe_answer_callback_query/d' {} \
```

---

## 6. Логгирование и отладка

### 6.1. Добавление логов

В `BaseCommand.safe_answer_callback_query`:
```ruby
Rails.logger.debug "Callback answered in #{self.class}: #{text || 'default'}"
```

В `BaseCommand.ensure_callback_answered`:
```ruby
Rails.logger.warn "Auto-answered callback in #{self.class}##{method} (developer forgot to call safe_answer_callback_query)"
```

### 6.2. Метрики для мониторинга

Счетчики (можно в StatsD/Prometheus):

```ruby
# В успешном ручном ответе
increment('telegram.callback.answered.manual')

# В автоматическом ответе
increment('telegram.callback.answered.auto')

# В ошибке ответа
increment('telegram.callback.answered.error')
```

---

## 7. Документация и чек-листы

### 7.1. Обновление AGENTS.md

Добавить в `docs/development/telegram-response-methods.md` раздел:

```markdown
## ✅ Правильная работа с callback_query

### Правило 1: Всегда отвечайте на callback_query

**ДО:**
```ruby
def projects_rename_callback_query(data)
  show_rename_menu(data)
end
```

**ПОСЛЕ:**
```ruby
def projects_rename_callback_query(data)
  show_rename_menu(data)
  safe_answer_callback_query('✏️ Меню переименования открыто')
end
```

### Правило 2: Отвечайте даже при ошибках

```ruby
def projects_rename_callback_query(data)
  unless data
    safe_answer_callback_query('❌ Ошибка', show_alert: true)
    return respond_with :message, text: 'Ошибка'
  end
  # ...
end
```
```

### 7.2. Чек-лист для новых callback методов

В шаблон нового callback метода добавить:

```ruby
def new_feature_callback_query(data = nil)
  unless data
    safe_answer_callback_query('❌ Ошибка', show_alert: true)
    return respond_with :message, text: 'Ошибка данных'
  end

  # ... логика обработки ...

  safe_answer_callback_query('✅ Успех')
end
```

### 7.3. Pull Request Template

```markdown
## Callback Query Changes Checklist

- [ ] Все новые `*_callback_query` методы вызывают `safe_answer_callback_query`
- [ ] Обработка ошибок с `safe_answer_callback_query('❌ Ошибка')`
- [ ] Тесты добавлены/обновлены
- [ ] Мануальное тестирование пройдено
- [ ] Нет зависших кнопок в UI
```

---

## 8. Оценка времени и ресурсов

### Этап 1: Safety Net (BaseCommand)
- Разработка: 1 час
- Тесты: 30 минут
- Ревью: 30 минут
- **Итого: 2 часа**

### Этап 2.1: report_command.rb (5 методов)
- Разработка: 30 минут
- Тесты: 30 минут
- Ревью: 20 минут
- **Итого: 1 час 20 минут**

### Этап 2.2: add_command.rb (1 метод)
- Разработка: 10 минут
- Тесты: 10 минут
- Ревью: 10 минут
- **Итого: 30 минут**

### Этап 2.3: users_command.rb (3 метода)
- Разработка: 20 минут
- Тесты: 20 минут
- Ревью: 15 минут
- **Итого: 55 минут**

### Этап 2.4: edit_command.rb (3 метода)
- Разработка: 20 минут
- Тесты: 20 минут
- Ревью: 15 минут
- **Итого: 55 минут**

### Этап 2.5: projects_command.rb (14 методов)
- Разработка: 2 часа
- Тесты: 1 час
- Ревью: 30 минут
- **Итого: 3 часа 30 минут**

### Этап 3: Интеграционные тесты
- Разработка: 1 час
- Ревью: 30 минут
- **Итого: 1 час 30 минут**

### Документация и мониторинг
- Документация: 30 минут
- Дашборды: 30 минут
- **Итого: 1 час**

---

## **ОБЩЕЕ ВРЕМЯ: ~10 часов** (разбито на 2-3 дня)

---

## 9. Риски и их смягчение

| Риск | Вероятность | Влияние | Смягчение |
|------|------------|---------|-----------|
| Забыть добавить в новый метод | Средняя | Среднее | Safety net из этапа 1, линтеры, чек-листы |
| Пользователь не увидит alert | Низкая | Низкое | Тесты UI, мануальное тестирование |
| Дублирование answerCallbackQuery | Низкая | Высокое | Флаг `@callback_answered`, тесты |
| Производительность (лишние вызовы) | Низкая | Низкое | Автоматический ответ только если забыли |
| Старые клиенты не поддерживают | Очень низкая | Низкое | Telegram API гарантирует обратную совместимость |

---

## 10. Определения

- **Callback Query**: Запрос от Telegram при нажатии inline-кнопки
- **Answer Callback Query**: Ответ бота, подтверждающий получение и обработку
- **Safety Net**: Автоматический ответ, если разработчик забыл вызвать вручную
- **`safe_answer_callback_query`**: Обертка над `answer_callback_query` с отслеживанием и обработкой ошибок

---

## 11. Ссылки

- [Анализ проблемы](docs/development/telegram-callback-query-analysis.md)
- [Руководство по методам ответов](docs/development/telegram-response-methods.md)
- [Telegram Bot API: answerCallbackQuery](https://core.telegram.org/bots/api#answercallbackquery)
- [Callback Query Guide](docs/development/telegram-callback-guide.md)

---

**Авторы плана:** AI Assistant  
**Дата последнего обновления:** 2025-11-15  
**Версия:** 1.0  
**Статус:** Готов к реализации  
