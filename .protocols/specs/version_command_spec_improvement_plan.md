# План улучшения спецификаций для version_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `VersionCommand` имеет только базовый тест на отсутствие ошибок. Команда простая, но требует проверки корректности вывода информации о версии.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет содержимое ответа
- Не проверяется формат версии
- Не проверяется наличие текста "Версия Маши"
- Нет тестов для разных состояний переменной AppVersion

## План улучшения

### 1. Тестирование корректности ответа
**Цель**: Проверить правильность формата и содержимого сообщения с версией
- Проверить наличие текста "Версия Маши"
- Проверить наличие номера версии
- Проверить формат сообщения

### 2. Тестирование переменной AppVersion
**Цель**: Убедиться, что версия корректно отображается
- Проверить, что AppVersion не пустая
- Проверить формат версии (соответствие semver)
- Тест с мокированной версией

### 3. Тестирование edge cases
**Цель**: Обеспечить стабильность при разных значениях версии
- Пустая строка версии
- nil значение версии
- Очень длинная строка версии
- Специальные символы в версии

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

    context 'version information' do
      it 'responds with version message containing proper text' do
        response = dispatch_command :version

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Версия Маши')
      end

      it 'includes actual version number' do
        response = dispatch_command :version

        expect(response.first[:text]).to include(AppVersion.to_s)
        expect(AppVersion).not_to be_empty
      end

      it 'has proper message format' do
        response = dispatch_command :version

        expect(response.first[:text]).to match(/Версия Маши: .+/)
      end
    end

    context 'version format validation' do
      it 'displays version that follows semver pattern' do
        response = dispatch_command :version

        version_text = response.first[:text]
        version_number = version_text.split(':').last.strip

        # Базовая проверка формата версии (может содержать цифры, точки, тире)
        expect(version_number).to match(/[\d\.\-a-zA-Z]+/)
      end
    end

    context 'with mocked version' do
      before do
        stub_const('AppVersion', '1.2.3-test')
      end

      it 'displays mocked version correctly' do
        response = dispatch_command :version

        expect(response.first[:text]).to eq('Версия Маши: 1.2.3-test')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds to version command without authentication' do
      response = dispatch_command :version

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Версия Маши')
      expect(response.first[:text]).to include(AppVersion.to_s)
    end
  end

  context 'version handling edge cases' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'when AppVersion is empty' do
      before do
        stub_const('AppVersion', '')
      end

      it 'handles empty version gracefully' do
        expect {
          response = dispatch_command :version
          expect(response.first[:text]).to eq('Версия Маши: ')
        }.not_to raise_error
      end
    end

    context 'when AppVersion contains special characters' do
      before do
        stub_const('AppVersion', 'v1.2.3-alpha+build.123')
      end

      it 'displays version with special characters' do
        response = dispatch_command :version

        expect(response.first[:text]).to eq('Версия Маши: v1.2.3-alpha+build.123')
      end
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование корректности ответа с версией
2. Проверка формата сообщения
3. Тест с реальной переменной AppVersion

### Средний приоритет
1. Тестирование для неавторизованных пользователей
2. Тест с мокированной версией

### Низкий приоритет
1. Тесты edge cases (пустая версия, специальные символы)

## Необходимые моки и фикстуры

### Fixed fixtures
- `AppVersion` - реальная переменная приложения

### Dynamic mocks
- Мокирование `AppVersion` для тестов с различными значениями версии

## Ожидаемые результаты
- Полное покрытие логики команды VersionCommand
- Уверенность в корректном отображении версии приложения
- Стабильность при различных значениях переменной AppVersion
- Документация формата вывода версии через тесты

## Примечания
- Команда VersionCommand относительно простая, поэтому спецификация не требует сложных сценариев
- Основное внимание уделено проверке корректности вывода и обработки различных значений версии
- Тесты должны быть устойчивы к изменениям формата версии в будущем