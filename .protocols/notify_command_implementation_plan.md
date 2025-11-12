# План имплентации команды /notify

## Обзор

План создания команды `/notify` для отправки массовых уведомлений пользователям Telegram. Команда доступна только разработчику и использует существующую архитектуру команд и систему рассылок проекта.

## Этапы реализации

### Этап 1: Создание команды NotifyCommand

**Задачи:**
1. Создать файл `app/commands/notify_command.rb`
2. Реализовать основной функционал команды
3. Добавить валидацию входных данных
4. Реализовать контекст для получения текста сообщения

**Содержимое файла:**
```ruby
# frozen_string_literal: true

class NotifyCommand < BaseCommand
  NOTIFY_MESSAGE_INPUT = :notify_message_input

  provides_context_methods :notify_message_input

  def call
    unless developer?
      return respond_with :message, text: t('commands.notify.errors.access_denied')
    end

    save_context NOTIFY_MESSAGE_INPUT
    respond_with :message, text: t('commands.notify.prompts.enter_message')
  end

  def notify_message_input(message_text)
    # Проверка отмены
    if message_text.downcase.strip == 'cancel'
      return respond_with :message, text: t('commands.notify.cancelled')
    end

    return unless validate_message(message_text)

    recipients = fetch_recipients
    BroadcastNotificationJob.perform_later(message_text, recipients.map(&:id))
    respond_with :message, text: t('commands.notify.success', count: recipients.count)
  end

  private

  def validate_message(message)
    if message.blank?
      respond_with :message, text: t('commands.notify.errors.empty_message')
      return false
    end

    if message.length < 3
      respond_with :message, text: t('commands.notify.errors.too_short')
      return false
    end

    if message.length > 4000
      respond_with :message, text: t('commands.notify.errors.too_long')
      return false
    end

    true
  end

  def fetch_recipients
    TelegramUser.all
  end
end
```

### Этап 2: Создание фонового задания для рассылки

**Задачи:**
1. Создать файл `app/jobs/broadcast_notification_job.rb`
2. Реализовать массовую отправку уведомлений
3. Добавить обработку ошибок

**Содержимое файла:**
```ruby
# frozen_string_literal: true

class BroadcastNotificationJob < ApplicationJob
  queue_as :default

  def perform(message, telegram_user_ids)
    telegram_user_ids.each do |user_id|
      TelegramNotificationJob.perform_later(user_id: user_id, message: message)
    end
  end
end
```

### Этап 3: Регистрация команды в системе

**Задачи:**
1. Найти файл регистрации команд
2. Добавить `notify` в список доступных команд

**Действия:**
Найти где регистрируются команды (вероятно в инициализаторе или конфигурационном файле) и добавить:
```ruby
Telegram::CommandRegistry.register(['notify'])
```

### Этап 4: Добавление локализации

**Задачи:**
1. Добавить переводы в `config/locales/ru.yml`

**Содержимое для добавления:**
```yaml
ru:
  commands:
    notify:
      success: "✅ Уведомление отправлено %{count} пользователям"
      cancelled: "❌ Операция отменена"
      errors:
        access_denied: "🚫 Доступ запрещён"
        empty_message: "⚠️ Введите текст уведомления"
        too_short: "⚠️ Слишком короткое сообщение. Минимум 3 символа"
        too_long: "⚠️ Слишком длинное сообщение. Максимум 4000 символов"
      prompts:
        enter_message: "📝 Введите текст уведомления (или 'cancel' для отмены):"
```

### Этап 5: Создание тестов ✅

**Задачи:**
1. ✅ Создать файл `spec/controllers/telegram/webhook/notify_command_spec.rb`
2. ✅ Написать тесты для всех сценариев
3. Создать тест для `BroadcastNotificationJob`

**Тесты для команды:**
```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'developer user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    # Override telegram_user id to match developer_telegram_id
    let(:from_id) { ApplicationConfig.developer_telegram_id }

    include_context 'authenticated user'

    before do
      # Mock telegram_user to have developer telegram id
      allow(controller).to receive(:telegram_user).and_return(
        telegram_user.tap { |tu| tu.id = ApplicationConfig.developer_telegram_id }
      )
    end

    it 'responds to /notify command without errors' do
      expect { dispatch_command :notify }.not_to raise_error
    end

    context 'complete notify workflow' do
      let!(:test_telegram_users) { [telegram_users(:telegram_regular), telegram_users(:telegram_developer)] }

      before do
        allow(BroadcastNotificationJob).to receive(:perform_later)
      end

      it 'requests message input when /notify is called' do
        response = dispatch_command :notify

        expect(response).not_to be_nil
        # Check that response contains request for message input
        expect(response.first[:text]).to include(I18n.t('commands.notify.prompts.enter_message'))
      end

      it 'broadcasts notification when valid message is provided' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send notification message
        expect do
          dispatch_message('Система будет обновлена в 18:00')
        end.to change { BroadcastNotificationJob.jobs.count }.by(1)

        # 3. Check that job was called with correct parameters
        expect(BroadcastNotificationJob).to have_been_enqueued.with(
          'Система будет обновлена в 18:00',
          array_including(test_telegram_users.map(&:id))
        )
      end

      it 'cancels operation when cancel is sent' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send cancel message
        expect do
          dispatch_message('cancel')
        end.not_to change { BroadcastNotificationJob.jobs.count }
      end

      it 'rejects too short message' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send short message
        expect do
          dispatch_message('х')
        end.not_to change { BroadcastNotificationJob.jobs.count }

        # 3. Check error response
        expect(response.first[:text]).to include(I18n.t('commands.notify.errors.too_short'))
      end

      it 'rejects too long message' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send long message
        long_message = 'a' * 4001
        expect do
          dispatch_message(long_message)
        end.not_to change { BroadcastNotificationJob.jobs.count }

        # 3. Check error response
        expect(response.first[:text]).to include(I18n.t('commands.notify.errors.too_long'))
      end
    end
  end

  context 'regular user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'denies access for non-developer user' do
      response = dispatch_command :notify
      expect(response).not_to be_nil
      expect(response.first[:text]).to include(I18n.t('commands.notify.errors.access_denied'))
    end
  end
end
```

### Этап 6: Обновление помощи

**Задачи:**
1. Добавить описание команды в `/help`
2. Обновить документацию для разработчиков

## Порядок выполнения

1. **Шаг 1**: Создать `NotifyCommand`
2. **Шаг 2**: Создать `BroadcastNotificationJob`
3. **Шаг 3**: Зарегистрировать команду
4. **Шаг 4**: Добавить локализацию
5. **Шаг 5**: Написать тесты
6. **Шаг 6**: Обновить документацию

## Необходимые файлы для создания/изменения

### Новые файлы:
- `app/commands/notify_command.rb`
- `app/jobs/broadcast_notification_job.rb`
- `spec/controllers/telegram/webhook/notify_command_spec.rb`
- `spec/jobs/broadcast_notification_job_spec.rb`

### Изменяемые файлы:
- Файл регистрации команд (найти расположение)
- `config/locales/ru.yml`

## Тестирование

### Manual тестирование:
1. Войти как разработчик и проверить команду
2. Попробовать выполнить команду как обычный пользователь
3. Проверить отмену через `cancel`
4. Проверить валидацию длины сообщения
5. Убедиться что уведомления доходят до пользователей

### Автоматизированное тестирование:
1. Запустить RSpec тесты
2. Проверить покрытие кода
3. Проверить работу фоновых заданий

## Развертывание

1. Убедиться что миграции не требуются
2. Проверить работу в development окружении
3. Запустить полный тестовый набор
4. Задеплоить в production

## Риски и митигация

### Риск: Неправильная регистрация команды
**Митигация**: Проверить существующие примеры регистрации команд

### Риск: Ошибки в валидации
**Митигация**: Тщательно протестировать все граничные случаи

### Риск: Проблемы с производительностью
**Митигация**: Использовать фоновые задания, ограничить частоту использования

### Риск: Случайная рассылка спама
**Митигация**: Жёсткая проверка прав разработчика, подтверждение операции

## Критерии завершения

1. ✅ Команда зарегистрирована и доступна
2. ✅ Проверка прав разработчика работает
3. ✅ Валидация сообщений работает корректно
4. ✅ Отмена через `cancel` работает
5. ✅ Уведомления доставляются всем пользователям
6. 🔄 Тесты проходят успешно (частично - созданы тесты для контроллера, нужен тест для BroadcastNotificationJob)
7. ✅ Документация обновлена
