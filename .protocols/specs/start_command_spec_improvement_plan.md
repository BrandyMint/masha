# План улучшения спецификаций для start_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `StartCommand` имеет только базовый тест на отсутствие ошибок, но команда имеет две важные ветки логики:
1. Приветственное сообщение для авторизованных пользователей
2. Обработка аутентификации через токен

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет правильность ответа
- Отсутствует тестирование функционала аутентификации
- Не проверяется генерация и валидация токена
- Нет тестов для невалидных токенов

## План улучшения

### 1. Тестирование приветственного сообщения
**Цель**: Проверить корректность ответа для авторизованных пользователей
- Проверить наличие текста приветствия
- Проверить наличие справочной информации (help_message)
- Проверить формат multiline сообщения

### 2. Тестирование аутентификации через токен
**Цель**: Полностью покрыть логику аутентификации
- Тест с валидным токеном авторизации
- Проверка генерации правильного URL для перехода
- Тест с невалидным токеном
- Тест с просроченным токеном
- Тест с токеном неверного формата

### 3. Тестирование edge cases
**Цель**: Обеспечить стабильность в пограничных случаях
- Пустой параметр
- Нулевой параметр (nil)
- Параметр без префикса AUTH_PREFIX
- Параметр с неправильным префиксом

### 4. Тестирование безопасности
**Цель**: Проверить защиту от атак
- Много крактеров в токене
- Специальные символы в параметре
- Попытка подделки токена

## Структура улучшенной спецификации

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without auth parameter' do
      it 'responds with welcome message' do
        response = dispatch_command :start

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('С возращением!')
      end

      it 'includes help information in welcome message' do
        response = dispatch_command :start

        expect(response.first[:text]).to include('help')
      end
    end

    context 'with auth parameter' do
      context 'valid auth token' do
        let(:session_token) { 'valid_session_token_123' }
        let(:auth_param) { "#{TelegramHelper::AUTH_PREFIX}#{session_token}" }

        it 'generates proper authorization URL' do
          response = dispatch_command :start, auth_param

          expect(response.first[:text]).to include('Вы авторизованы!')
          expect(response.first[:text]).to include('telegram_confirm')
        end

        it 'includes generated token in URL' do
          response = dispatch_command :start, auth_param

          expect(response.first[:text]).to match(/token=[a-zA-Z0-9\-_]+/)
        end
      end

      context 'invalid auth token' do
        let(:invalid_auth_param) { "#{TelegramHelper::AUTH_PREFIX}invalid_token" }

        it 'handles invalid token gracefully' do
          expect {
            dispatch_command :start, invalid_auth_param
          }.not_to raise_error
        end
      end

      context 'malformed auth parameter' do
        it 'handles empty auth parameter' do
          expect {
            dispatch_command :start, ''
          }.not_to raise_error
        end

        it 'handles parameter without AUTH_PREFIX' do
          expect {
            dispatch_command :start, 'no_prefix_token'
          }.not_to raise_error
        end
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'handles start command without authentication' do
      expect {
        dispatch_command :start
      }.not_to raise_error
    end

    it 'processes auth parameter for unauthenticated user' do
      session_token = 'new_user_session_token'
      auth_param = "#{TelegramHelper::AUTH_PREFIX}#{session_token}"

      expect {
        dispatch_command :start, auth_param
      }.not_to raise_error
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование приветственного сообщения для авторизованных пользователей
2. Тестирование аутентификации с валидным токеном
3. Базовые edge cases

### Средний приоритет
1. Тестирование невалидных токенов
2. Тест для неавторизованных пользователей

### Низкий приоритет
1. Тесты безопасности
2. Комплексные edge cases

## Необходимые моки и фикстуры

### Fixed fixtures
- `TelegramHelper::AUTH_PREFIX` - можно использовать реальную константу
- `AppVersion` - должна быть доступна в тестовом окружении

### Dynamic mocks
- `Rails.application.message_verifier` - может потребоваться мок для детальной проверки
- `Rails.application.routes.url_helpers` - для проверки генерации URL

## Ожидаемые результаты
- Полное покрытие логики команды StartCommand
- Уверенность в корректной работе аутентификации через Telegram
- Стабильность при обработке некорректных входных данных
- Документация поведения команды через тесты