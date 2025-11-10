# План улучшения спецификаций для help_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `HelpCommand` имеет только базовый тест на отсутствие ошибок. Команда справки критически важна для пользователей и должна иметь полное покрытие тестами.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет содержимое справки
- Не проверяется наличие информации о доступных командах
- Не проверяется форматирование справочного сообщения
- Нет тестов для разных ролей пользователей
- Отсутствует проверка доступности команды для неавторизованных пользователей

## План улучшения

### 1. Тестирование содержимого справки
**Цель**: Проверить полноту и корректность справочной информации
- Проверить наличие списка команд
- Проверить наличие описаний команд
- Проверить форматирование (разделители, структуры)

### 2. Тестирование для разных ролей
**Цель**: Убедиться, что справка адаптируется под роль пользователя
- Тест для пользователя с проектами (member/owner)
- Тест для пользователя без проектов
- Тест для viewer роли в проектах

### 3. Тестирование доступности
**Цель**: Проверить работу команды для разных состояний аутентификации
- Авторизованный пользователь
- Неавторизованный пользователь
- Пользователь с неподключенным Telegram

### 4. Тестирование форматирования
**Цель**: Убедиться в правильном форматировании справочного сообщения
- Проверка переноса строк
- Проверка использования markdown (если применимо)
- Проверка разделителей и структуры

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

    context 'basic help functionality' do
      it 'responds with help message' do
        response = dispatch_command :help

        expect(response).not_to be_nil
        expect(response.first[:text]).not_to be_empty
      end

      it 'includes list of available commands' do
        response = dispatch_command :help

        # Проверяем наличие основных команд
        expect(response.first[:text]).to include('/start')
        expect(response.first[:text]).to include('/help')
        expect(response.first[:text]).to include('/projects')
        expect(response.first[:text]).to include('/add')
      end

      it 'includes command descriptions' do
        response = dispatch_command :help

        # Проверяем наличие описаний команд
        expect(response.first[:text]).to match(/\/add.*?время/i)
        expect(response.first[:text]).to match(/\/projects.*?проекты/i)
      end
    end

    context 'user with projects' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'member') }

      it 'includes project-specific commands in help' do
        response = dispatch_command :help

        expect(response.first[:text]).to include('/report')
        expect(response.first[:text]).to include('/summary')
        expect(response.first[:text]).to include('/day')
      end
    end

    context 'user as project owner' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'includes owner-specific commands in help' do
        response = dispatch_command :help

        expect(response.first[:text]).to include('/users')
        expect(response.first[:text]).to include('/merge')
        expect(response.first[:text]).to include('/rate')
      end
    end

    context 'user as viewer' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'includes appropriate commands for viewer role' do
        response = dispatch_command :help

        expect(response.first[:text]).to include('/projects')
        expect(response.first[:text]).to include('/day')
        # Не должно включать команды только для owner
        expect(response.first[:text]).not_to include('/users')
      end
    end

    context 'user without projects' do
      it 'shows basic commands for new users' do
        response = dispatch_command :help

        expect(response.first[:text]).to include('/start')
        expect(response.first[:text]).to include('/new')
        expect(response.first[:text]).to include('/attach')
      end

      it 'does not show project-specific commands' do
        response = dispatch_command :help

        expect(response.first[:text]).not_to include('/add')
        expect(response.first[:text]).not_to include('/report')
        expect(response.first[:text]).not_to include('/day')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds with basic help for unauthenticated users' do
      response = dispatch_command :help

      expect(response).not_to be_nil
      expect(response.first[:text]).not_to be_empty
    end

    it 'includes authentication commands' do
      response = dispatch_command :help

      expect(response.first[:text]).to include('/start')
      expect(response.first[:text]).to include('/attach')
    end

    it 'does not include project-specific commands' do
      response = dispatch_command :help

      expect(response.first[:text]).not_to include('/add')
      expect(response.first[:text]).not_to include('/projects')
      expect(response.first[:text]).not_to include('/report')
    end
  end

  context 'message formatting' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'formats help message with proper separators' do
      response = dispatch_command :help

      # Проверяем наличие переносов строк для форматирования
      expect(response.first[:text]).to include("\n")
    end

    it 'groups commands logically' do
      response = dispatch_command :help

      text = response.first[:text]

      # Проверяем логическую группировку команд
      # (эти проверки зависят от конкретной реализации форматирования)
      expect(text).to match(/Основные команды|Базовые/i)
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование базового функционала справки
2. Тестирование для пользователя с проектами
3. Тестирование для неавторизованных пользователей

### Средний приоритет
1. Тестирование для разных ролей (owner/viewer)
2. Проверка форматирования сообщения

### Низкий приоритет
1. Тестирование edge cases
2. Детальная проверка группировки команд

## Необходимые моки и фикстуры

### Fixed fixtures
- Стандартные фикстуры пользователей и проектов
- Telegram webhook контекст

### Dynamic mocks
- Возможна потребность в мокировании форматирования, если используются сложные методы форматирования

## Ожидаемые результаты
- Полное покрытие логики команды HelpCommand
- Уверенность в корректном отображении справки для разных типов пользователей
- Стабильность при работе с различными ролями и состояниями аутентификации
- Документация доступных команд через тесты

## Примечания
- HelpCommand критически важна для пользовательского опыта
- Тесты должны отражать фактическое поведение команды и ее адаптивность под роль пользователя
- При изменении списка команд тесты помогут обеспечить актуальность справки