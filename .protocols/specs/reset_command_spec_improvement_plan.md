# План улучшения спецификаций для reset_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `ResetCommand` имеет только базовый тест на отсутствие ошибок. Команда критически важна для сброса состояния сессии пользователя и имеет сложную логику очистки различных типов данных сессии.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет фактический сброс сессии
- Не проверяется очистка telegram_session_keys
- Не проверяется очистка контекста
- Не проверяется очистка различных типов ключей сессии
- Отсутствует тестирование сообщения об успехе

## План улучшения

### 1. Тестирование сброса сессии
**Цель**: Проверить корректную очистку всех данных сессии
- Проверить очистку telegram_session_keys
- Проверить очистку контекста
- Проверить очистку специальных ключей сессии
- Проверить сохранение не-Telegram данных в сессии

### 2. Тестирование сообщения об успехе
**Цель**: Убедиться в корректном сообщении после сброса
- Проверить наличие текста успешного сброса
- Проверить использование правильной локализации
- Проверить формат сообщения

### 3. Тестирование различных состояний сессии
**Цель**: Проверить работу сессии в разных начальных состояниях
- Сессия с контекстом
- Сессия с telegram ключами
- Сессия со специальными ключами
- Пустая сессия

### 4. Тестирование сохранения важных данных
**Цель**: Убедиться, что важные данные не удаляются
- Данные аутентификации пользователя
- Другие не-Telegram данные сессии

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

    context 'basic reset functionality' do
      it 'responds with success message' do
        response = dispatch_command :reset

        expect(response).not_to be_nil
        expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
      end

      it 'clears session context' do
        # Устанавливаем контекст в сессии
        session[:context] = 'add_time'

        response = dispatch_command :reset

        expect(session[:context]).to be_nil
      end

      it 'clears telegram session keys' do
        # Устанавливаем telegram ключи сессии
        session[:telegram_user_id] = from_id
        session[:telegram_project_id] = 123

        dispatch_command :reset

        expect(session[:telegram_user_id]).to be_nil
        expect(session[:telegram_project_id]).to be_nil
      end

      it 'clears special session keys' do
        # Устанавливаем специальные ключи
        session[:edit_client_key] = 'client_123'
        session[:client_name] = 'Test Client'
        session[:edit_project_key] = 'project_456'

        dispatch_command :reset

        expect(session[:edit_client_key]).to be_nil
        expect(session[:client_name]).to be_nil
        expect(session[:edit_project_key]).to be_nil
      end
    end

    context 'session with existing context' do
      before do
        session[:context] = 'add_time_entry'
      end

      it 'clears context and sends success message' do
        response = dispatch_command :reset

        expect(session[:context]).to be_nil
        expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
      end
    end

    context 'session with mixed telegram and non-telegram data' do
      before do
        # Telegram данные
        session[:telegram_user_id] = from_id
        session[:telegram_project_id] = 123
        session[:context] = 'edit_project'

        # Не-Telegram данные (должны сохраниться)
        session[:user_preference] = 'dark_theme'
        session[:last_page] = '/dashboard'
        session[:custom_data] = { key: 'value' }
      end

      it 'clears only telegram-related data' do
        dispatch_command :reset

        # Telegram данные должны быть очищены
        expect(session[:telegram_user_id]).to be_nil
        expect(session[:telegram_project_id]).to be_nil
        expect(session[:context]).to be_nil

        # Не-Telegram данные должны сохраниться
        expect(session[:user_preference]).to eq('dark_theme')
        expect(session[:last_page]).to eq('/dashboard')
        expect(session[:custom_data]).to eq({ key: 'value' })
      end
    end

    context 'empty session' do
      it 'handles empty session gracefully' do
        expect {
          response = dispatch_command :reset
          expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
        }.not_to raise_error
      end
    end

    context 'session with only non-telegram data' do
      before do
        session[:user_id] = user.id
        session[:csrf_token] = 'security_token'
        session[:flash] = { notice: 'Welcome' }
      end

      it 'preserves non-telegram data' do
        dispatch_command :reset

        expect(session[:user_id]).to eq(user.id)
        expect(session[:csrf_token]).to eq('security_token')
        expect(session[:flash]).to eq({ notice: 'Welcome' })
      end
    end

    context 'complex session state' do
      before do
        # Создаем сложное состояние сессии
        session[:telegram_user_id] = from_id
        session[:telegram_current_project] = 456
        session[:context] = 'merge_projects'
        session[:edit_client_key] = 'client_789'
        session[:client_name] = 'Important Client'
        session[:edit_project_key] = 'project_101'
        session[:user_locale] = 'ru'
        session[:last_activity] = 1.hour.ago
        session[:temporary_data] = { temp: 'value' }
      end

      it 'selectively clears telegram-related keys' do
        dispatch_command :reset

        # Очищенные ключи
        expect(session[:telegram_user_id]).to be_nil
        expect(session[:telegram_current_project]).to be_nil
        expect(session[:context]).to be_nil
        expect(session[:edit_client_key]).to be_nil
        expect(session[:client_name]).to be_nil
        expect(session[:edit_project_key]).to be_nil

        # Сохраненные ключи
        expect(session[:user_locale]).to eq('ru')
        expect(session[:last_activity]).to eq(1.hour.ago)
        expect(session[:temporary_data]).to eq({ temp: 'value' })
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds with reset message for unauthenticated user' do
      response = dispatch_command :reset

      expect(response).not_to be_nil
      expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
    end

    it 'clears telegram session data for unauthenticated user' do
      session[:telegram_user_id] = from_id
      session[:context] = 'auth_flow'

      dispatch_command :reset

      expect(session[:telegram_user_id]).to be_nil
      expect(session[:context]).to be_nil
    end
  end

  context 'session key detection' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'identifies and clears telegram_prefixed keys' do
      session[:telegram_user_id] = from_id
      session[:telegram_project_id] = 123
      session[:telegram_command_state] = 'active'
      session[:telegram_temp_data] = 'temp'

      dispatch_command :reset

      %w[telegram_user_id telegram_project_id telegram_command_state telegram_temp_data].each do |key|
        expect(session[key.to_sym]).to be_nil
      end
    end

    it 'identifies and clears special keys' do
      session[:context] = 'add_entry'
      session[:edit_client_key] = 'client_123'
      session[:client_name] = 'Test Client'
      session[:edit_project_key] = 'project_456'

      dispatch_command :reset

      %w[context edit_client_key client_name edit_project_key].each do |key|
        expect(session[key.to_sym]).to be_nil
      end
    end

    it 'preserves non-telegram keys even with similar names' do
      session[:telegram_style] = 'modern'  # Should be cleared
      session[:telegram_user_pref] = 'dark' # Should be cleared
      session[:user_telegram_setting] = 'enabled' # Should be preserved
      session[:telegram_backup] = 'data' # Should be cleared

      dispatch_command :reset

      expect(session[:telegram_style]).to be_nil
      expect(session[:telegram_user_pref]).to be_nil
      expect(session[:telegram_backup]).to be_nil
      expect(session[:user_telegram_setting]).to eq('enabled')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование базового сброса сессии
2. Тестирование очистки контекста
3. Тестирование сообщения об успехе

### Средний приоритет
1. Тестирование смешанных данных сессии
2. Тестирование обнаружения telegram ключей
3. Тестирование сохранения не-Telegram данных

### Низкий приоритет
1. Сложные сценарии сессии
2. Edge cases с необычными ключами

## Необходимые моки и фикстуры

### Fixed fixtures
- Стандартные фикстуры пользователей
- Telegram webhook контекст

### Dynamic mocks
- Мокирование `I18n.t` для проверки локализации (опционально)

## Ожидаемые результаты
- Полное покрытие логики сброса сессии
- Уверенность в корректной очистке только Telegram данных
- Сохранение важных не-Telegram данных
- Стабильность при работе с различными состояниями сессии

## Примечания
- ResetCommand критически важна для восстановления рабочего состояния бота
- Важно тщательно тестировать, что только нужные данные удаляются
- Сессия может содержать важные данные аутентификации, которые не должны удаляться