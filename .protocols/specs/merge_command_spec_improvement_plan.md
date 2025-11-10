# План улучшения спецификаций для merge_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `MergeCommand` имеет базовое покрытие, но команда является критически важной административной функцией для слияния пользователей и требует более детального тестирования различных сценариев.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет фактические ответы
- Не проверяется валидация параметров (email, username)
- Отсутствует тестирование текста ошибок и сообщений использования
- Нет тестирования интеграции с TelegramUserMerger
- Не проверяются edge cases для невалидных данных

## План улучшения

### 1. Тестирование валидации параметров
**Цель**: Проверить корректную обработку входных параметров
- Проверка отсутствия email
- Проверка отсутствия username
- Проверка обоих отсутствующих параметров
- Валидация формата email

### 2. Тестирование прав доступа
**Цель**: Убедиться в корректной проверке прав разработчика
- Обычный пользователь не может выполнить команду
- Разработчик может выполнить команду
- Проверка сообщения об отсутствии прав

### 3. Тестирование сообщений
**Цель**: Проверить корректность всех сообщений
-Сообщение об использовании при отсутствии параметров
- Сообщение о недоступности команды для обычных пользователей
- Сообщения об успехе/ошибке слияния

### 4. Тестирование интеграции
**Цель**: Проверить взаимодействие с TelegramUserMerger
- Вызов сервиса с правильными параметрами
- Обработка результатов слияния
- Обработка ошибок сервиса

### 5. Тестирование edge cases
**Цель**: Обеспечить стабильность в пограничных случаях
- Некорректный формат email
- Специальные символы в username
- Пустые строки в параметрах
- Очень длинные параметры

## Структура улучшенной спецификации

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated regular user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'rejects merge command with access denied message' do
      response = dispatch_command :merge, 'test@example.com', 'testuser'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Эта команда доступна только разработчику системы')
    end

    it 'rejects merge command without parameters' do
      response = dispatch_command :merge

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Эта команда доступна только разработчику системы')
    end

    it 'handles merge command gracefully without crashing' do
      expect {
        dispatch_command :merge, 'test@example.com', 'testuser'
      }.not_to raise_error
    end
  end

  context 'authenticated developer user' do
    let(:developer_telegram_id) { ApplicationConfig.developer_telegram_id }
    let(:user) { create(:user, :with_telegram_id, telegram_id: developer_telegram_id) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { developer_telegram_id }

    include_context 'authenticated user'

    context 'parameter validation' do
      it 'shows usage message when email is missing' do
        response = dispatch_command :merge, nil, 'testuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование: /merge email@example.com telegram_username')
      end

      it 'shows usage message when telegram_username is missing' do
        response = dispatch_command :merge, 'test@example.com'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование: /merge email@example.com telegram_username')
      end

      it 'shows usage message when both parameters are missing' do
        response = dispatch_command :merge

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование: /merge email@example.com telegram_username')
      end

      it 'shows usage message when email is empty string' do
        response = dispatch_command :merge, '', 'testuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование: /merge email@example.com telegram_username')
      end

      it 'shows usage message when username is empty string' do
        response = dispatch_command :merge, 'test@example.com', ''

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование: /merge email@example.com telegram_username')
      end
    end

    context 'valid parameters' do
      let(:email) { 'test@example.com' }
      let(:telegram_username) { 'testuser' }

      it 'calls TelegramUserMerger with correct parameters' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with(email, telegram_username, controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, email, telegram_username
      end

      it 'handles merge command without errors' do
        allow(TelegramUserMerger).to receive_message_chain(:new, :merge)

        expect {
          dispatch_command :merge, email, telegram_username
        }.not_to raise_error
      end
    end

    context 'email format validation' do
      it 'attempts merge with invalid email format' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('invalid-email', 'testuser', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'invalid-email', 'testuser'
      end

      it 'handles email without domain' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('user@', 'testuser', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'user@', 'testuser'
      end
    end

    context 'telegram username formats' do
      it 'handles username with @ symbol' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('test@example.com', '@testuser', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'test@example.com', '@testuser'
      end

      it 'handles username with underscores' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('test@example.com', 'test_user', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'test@example.com', 'test_user'
      end

      it 'handles username with numbers' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('test@example.com', 'testuser123', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'test@example.com', 'testuser123'
      end
    end

    context 'error handling' do
      let(:email) { 'test@example.com' }
      let(:telegram_username) { 'testuser' }

      it 'handles TelegramUserMerger errors gracefully' do
        merger_service = instance_double(TelegramUserMerger)
        allow(TelegramUserMerger).to receive(:new).and_return(merger_service)
        allow(merger_service).to receive(:merge).and_raise(StandardError, 'Merge failed')

        expect {
          dispatch_command :merge, email, telegram_username
        }.not_to raise_error
      end

      it 'does not crash when TelegramUserMerger raises exception' do
        allow(TelegramUserMerger).to receive(:new).and_raise(StandardError, 'Service error')

        expect {
          dispatch_command :merge, email, telegram_username
        }.not_to raise_error
      end
    end

    context 'special characters and edge cases' do
      it 'handles email with special characters' do
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('test+tag@example.com', 'testuser', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'test+tag@example.com', 'testuser'
      end

      it 'handles very long email address' do
        long_email = "#{'a' * 100}@example.com"
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with(long_email, 'testuser', controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, long_email, 'testuser'
      end

      it 'handles very long telegram username' do
        long_username = 'user' + 'a' * 100
        merger_service = instance_double(TelegramUserMerger)
        expect(TelegramUserMerger).to receive(:new)
          .with('test@example.com', long_username, controller: controller)
          .and_return(merger_service)
        expect(merger_service).to receive(:merge)

        dispatch_command :merge, 'test@example.com', long_username
      end
    end

    context 'successful merge scenarios' do
      let(:email) { 'existing.user@example.com' }
      let(:telegram_username) { 'existing_user' }

      it 'processes successful merge without errors' do
        # Мокируем успешное слияние
        merger_service = instance_double(TelegramUserMerger)
        allow(TelegramUserMerger).to receive(:new).and_return(merger_service)
        allow(merger_service).to receive(:merge).and_return(true)

        expect {
          response = dispatch_command :merge, email, telegram_username
          expect(response).to be_truthy
        }.not_to raise_error
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'rejects merge command for unauthenticated user' do
      response = dispatch_command :merge, 'test@example.com', 'testuser'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Эта команда доступна только разработчику системы')
    end

    it 'shows access denied even with valid parameters' do
      response = dispatch_command :merge, 'valid@example.com', 'validuser'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Эта команда доступна только разработчику системы')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование прав доступа (разработчик vs обычный пользователь)
2. Валидация параметров (отсутствие, пустые строки)
3. Проверка сообщений об использовании

### Средний приоритет
1. Тестирование интеграции с TelegramUserMerger
2. Обработка ошибок сервиса
3. Разные форматы email и username

### Низкий приоритет
1. Edge cases с очень длинными параметрами
2. Специальные символы в параметрах

## Необходимые моки и фикстуры

### Fixed fixtures
- `ApplicationConfig.developer_telegram_id` - реальная конфигурация
- Фикстуры пользователей с разными telegram_id

### Dynamic mocks
- `TelegramUserMerger` - для тестирования интеграции и ошибок
- Контроллер для проверки передачи параметров

## Ожидаемые результаты
- Полное покрытие логики проверки прав доступа
- Уверенность в корректной валидации параметров
- Стабильность при обработке ошибок сервиса
- Четкое документирование поведения команды через тесты

## Примечания
- MergeCommand - критически важная административная функция
- Важно тщательно тестировать проверки прав доступа
- TelegramUserMerger может содержать сложную логику, которую нужно изолировать
- Команда должна быть устойчива к некорректным входным данным