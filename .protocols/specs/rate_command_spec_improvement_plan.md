# План улучшения спецификаций для rate_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `RateCommand` имеет базовое покрытие, но команда является сложной системой управления ставками с множеством функций: установка ставок, просмотр списка, удаление, валидация прав доступа. Требует комплексного тестирования всех сценариев.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет функциональность
- Отсутствует тестирование установки ставок
- Не проверяется просмотр списка ставок
- Нет тестирования удаления ставок
- Не проверяется валидация параметров и прав доступа
- Отсутствует тестирование разных ролей пользователей

## План улучшения

### 1. Тестирование установки ставок (handle_set_rate)
**Цель**: Проверить корректную установку часовых ставок
- Успешная установка ставки для пользователя
- Валидация обязательных параметров
- Проверка прав доступа (только owner)
- Валидация суммы и валюты
- Обработка некорректных проектов и пользователей

### 2. Тестирование просмотра списка (handle_list)
**Цель**: Проверить отображение списка ставок проекта
- Показ списка ставок для проекта
- Права доступа на просмотр
- Форматирование списка с пользователями и ставками
- Обработка проектов без ставок

### 3. Тестирование удаления ставок (handle_remove)
**Цель**: Проверить удаление часовых ставок
- Успешное удаление ставки
- Проверка прав на удаление
- Обработка попытки удаления несуществующей ставки
- Валидация параметров

### 4. Тестирование справки (show_rate_help)
**Цель**: Проверить отображение справочной информации
- Показ справки без параметров
- Корректное форматирование справки
- Наличие примеров использования

### 5. Тестирование прав доступа
**Цель**: Убедиться в корректной проверке ролей
- Owner может управлять ставками
- Member не может управлять ставками
- Viewer не может управлять ставками
- Попытка управления ставками в чужих проектах

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

    context 'rate help functionality' do
      it 'shows help message when called without arguments' do
        response = dispatch_command :rate

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование')
        expect(response.first[:text]).to include('/rate')
      end

      it 'includes command examples in help' do
        response = dispatch_command :rate

        expect(response.first[:text]).to match(/пример|usage/i)
      end

      it 'includes access notes in help' do
        response = dispatch_command :rate

        expect(response.first[:text]).to include('доступ')
      end
    end

    context 'setting rates' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let(:target_user) { create(:user, :with_telegram, username: 'targetuser') }

      before do
        create(:membership, :member, project: project, user: target_user)
      end

      it 'sets rate successfully with valid parameters' do
        response = dispatch_command :rate, project.slug, 'targetuser', '50', 'USD'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Ставка установлена')
        expect(response.first[:text]).to include('50 USD')
      end

      it 'sets rate with default currency RUB' do
        response = dispatch_command :rate, project.slug, 'targetuser', '1500'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('1500 RUB')
      end

      it 'updates existing rate' do
        # Создаем существующую ставку
        create(:member_rate, project: project, user: target_user, hourly_rate: 30, currency: 'USD')

        response = dispatch_command :rate, project.slug, 'targetuser', '40', 'USD'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('40 USD')
      end

      it 'validates required parameters' do
        response = dispatch_command :rate, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование')
      end

      it 'handles invalid amount' do
        response = dispatch_command :rate, project.slug, 'targetuser', '0'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('некорректная сумма')
      end

      it 'handles negative amount' do
        response = dispatch_command :rate, project.slug, 'targetuser', '-50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('некорректная сумма')
      end

      it 'handles invalid currency' do
        response = dispatch_command :rate, project.slug, 'targetuser', '50', 'INVALID'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('некорректная валюта')
      end

      it 'handles non-existent project' do
        response = dispatch_command :rate, 'nonexistent', 'targetuser', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end

      it 'handles non-existent user' do
        response = dispatch_command :rate, project.slug, 'nonexistentuser', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('пользователь не найден')
      end

      it 'handles user not in project' do
        non_member_user = create(:user, :with_telegram, username: 'nonmember')
        response = dispatch_command :rate, project.slug, 'nonmember', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не является участником')
      end
    end

    context 'listing rates' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let(:member_user) { create(:user, :with_telegram, username: 'member1') }
      let(:member_user2) { create(:user, :with_telegram, username: 'member2') }

      before do
        create(:membership, :member, project: project, user: member_user)
        create(:membership, :member, project: project, user: member_user2)
        create(:member_rate, project: project, user: member_user, hourly_rate: 50, currency: 'USD')
      end

      it 'shows rates list for project' do
        response = dispatch_command :rate, 'list', project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include(project.name)
        expect(response.first[:text]).to include('member1: 50 USD')
        expect(response.first[:text]).to include('member2: не установлена')
      end

      it 'requires project name for list command' do
        response = dispatch_command :rate, 'list'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('укажите проект')
      end

      it 'handles non-existent project for list' do
        response = dispatch_command :rate, 'list', 'nonexistent'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end
    end

    context 'removing rates' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let(:target_user) { create(:user, :with_telegram, username: 'targetuser') }
      let!(:member_rate) { create(:member_rate, project: project, user: target_user, hourly_rate: 50, currency: 'USD') }

      before do
        create(:membership, :member, project: project, user: target_user)
      end

      it 'removes rate successfully' do
        response = dispatch_command :rate, 'remove', project.slug, 'targetuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Ставка удалена')
      end

      it 'requires project and username for remove' do
        response = dispatch_command :rate, 'remove'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('укажите проект')
      end

      it 'handles non-existent rate for remove' do
        other_user = create(:user, :with_telegram, username: 'otheruser')
        response = dispatch_command :rate, 'remove', project.slug, 'otheruser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Ставка не установлена')
      end
    end

    context 'access control' do
      let!(:project) { create(:project, :with_owner) }
      let!(:other_project) { create(:project, :with_owner) }
      let(:target_user) { create(:user, :with_telegram, username: 'targetuser') }

      before do
        create(:membership, :member, project: project, user: user)
        create(:membership, :member, project: project, user: target_user)
        create(:membership, :owner, project: other_project, user: create(:user, :with_telegram))
        create(:membership, :member, project: other_project, user: target_user)
      end

      it 'allows owner to set rates' do
        owner_project = create(:project, name: 'Owner Project')
        create(:membership, :owner, project: owner_project, user: user)
        create(:membership, :member, project: owner_project, user: target_user)

        response = dispatch_command :rate, owner_project.slug, 'targetuser', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Ставка установлена')
      end

      it 'denies member from setting rates' do
        response = dispatch_command :rate, project.slug, 'targetuser', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступно только владельцу')
      end

      it 'denies member from listing rates' do
        response = dispatch_command :rate, 'list', project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступно только владельцу')
      end

      it 'denies member from removing rates' do
        create(:member_rate, project: project, user: target_user, hourly_rate: 50)
        response = dispatch_command :rate, 'remove', project.slug, 'targetuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступно только владельцу')
      end
    end

    context 'without projects' do
      it 'shows access denied when trying to set rate' do
        response = dispatch_command :rate, 'nonexistent', 'user', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end

      it 'shows help when called without arguments' do
        response = dispatch_command :rate

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Использование')
      end
    end

    context 'edge cases' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'handles comma in amount' do
        target_user = create(:user, :with_telegram, username: 'targetuser')
        create(:membership, :member, project: project, user: target_user)

        response = dispatch_command :rate, project.slug, 'targetuser', '50,5'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('50.5')
      end

      it 'handles decimal amount' do
        target_user = create(:user, :with_telegram, username: 'targetuser')
        create(:membership, :member, project: project, user: target_user)

        response = dispatch_command :rate, project.slug, 'targetuser', '75.25'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('75.25')
      end

      it 'handles username with @ symbol' do
        target_user = create(:user, :with_telegram, username: 'targetuser')
        create(:membership, :member, project: project, user: target_user)

        response = dispatch_command :rate, project.slug, '@targetuser', '50'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Ставка установлена')
      end

      it 'handles currency case insensitivity' do
        target_user = create(:user, :with_telegram, username: 'targetuser')
        create(:membership, :member, project: project, user: target_user)

        response = dispatch_command :rate, project.slug, 'targetuser', '50', 'usd'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('50 USD')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows help for unauthenticated user' do
      response = dispatch_command :rate

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Использование')
    end

    it 'denies rate setting for unauthenticated user' do
      response = dispatch_command :rate, 'project', 'user', '50'

      expect(response).not_to be_nil
      # Должна быть ошибка аутентификации или проект не найден
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование установки ставок (основная функция)
2. Тестирование прав доступа (owner vs member)
3. Тестирование валидации параметров

### Средний приоритет
1. Тестирование просмотра списка ставок
2. Тестирование удаления ставок
3. Тестирование справочной информации

### Низкий приоритет
1. Edge cases с форматированием данных
2. Интеграционные тесты с базой данных

## Необходимые моки и фикстуры

### Fixed fixtures
- Фикстуры пользователей с разными ролями
- Фикстуры проектов и memberships
- Фикстуры MemberRate для тестирования ставок

### Dynamic mocks
- Минимальное мокирование, фокус на реальном поведении
- Возможно мокирование I18n.t для проверки локализации

## Ожидаемые результаты
- Полное покрытие всех функций управления ставками
- Уверенность в корректной проверке прав доступа
- Стабильность при обработке некорректных данных
- Четкая документация API команды через тесты

## Примечания
- RateCommand имеет сложную логику с множеством веток
- Важно тщательно тестировать права доступа - это критическая функция
- Команда активно использует локализацию через I18n
- Нобходимо проверять обработку различных форматов входных данных