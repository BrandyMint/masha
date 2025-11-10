# План улучшения спецификаций для projects_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `ProjectsCommand` имеет только базовый тест на отсутствие ошибок. Команда отображает проекты пользователя и имеет важную логику форматирования, особенно при работе с клиентами.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет содержимое ответа
- Не проверяется правильность отображения проектов
- Не проверяется форматирование с клиентами
- Не проверяется случай отсутствия проектов
- Отсутствует тестирование для разных ролей пользователей

## План улучшения

### 1. Тестирование отображения проектов
**Цель**: Проверить корректность отображения списка проектов
- Проверить наличие заголовка "Доступные проекты:"
- Проверить правильность отображения имен проектов
- Проверить форматирование (маркеры, переносы строк)

### 2. Тестирование проектов с клиентами
**Цель**: Убедиться в корректном отображении информации о клиентах
- Отображение имени клиента в скобках
- Обработка проектов без клиента
- Форматирование информации о клиенте

### 3. Тестирование пустого списка проектов
**Цель**: Проверить корректную обработку отсутствия проектов
- Отображение сообщения "У вас пока нет проектов"
- Правильный формат сообщения при отсутствии проектов

### 4. Тестирование для разных ролей
**Цель**: Убедиться, что команда работает корректно для разных ролей
- Owner (владелец) - видит все свои проекты
- Member (участник) - видит проекты где участник
- Viewer (наблюдатель) - видит проекты где наблюдатель

### 5. Тестирование фильтрации проектов
**Цель**: Проверить правильную фильтрацию проектов
- Только "живые" проекты (alive)
- Только доступные пользователю проекты
- Правильная сортировка (если есть)

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

    context 'user with no projects' do
      it 'displays empty projects message' do
        response = dispatch_command :projects

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Доступные проекты:')
        expect(response.first[:text]).to include('У вас пока нет проектов.')
      end

      it 'has proper format for empty projects list' do
        response = dispatch_command :projects

        expect(response.first[:text]).to match(/Доступные проекты:\s*\n\s*У вас пока нет проектов\./)
      end
    end

    context 'user with projects' do
      let!(:project1) { create(:project, :with_owner, name: 'Work Project') }
      let!(:project2) { create(:project, :with_owner, name: 'Personal Project') }
      let!(:membership1) { create(:membership, :member, project: project1, user: user) }
      let!(:membership2) { create(:membership, :member, project: project2, user: user) }

      it 'displays projects header' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Доступные проекты:')
      end

      it 'lists all available projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Work Project')
        expect(response.first[:text]).to include('Personal Project')
      end

      it 'formats projects with bullet points' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('• Work Project')
        expect(response.first[:text]).to include('• Personal Project')
      end
    end

    context 'projects with clients' do
      let!(:client) { create(:client, name: 'Acme Corp') }
      let!(:project) { create(:project, :with_owner, name: 'Website Project', client: client) }
      let!(:membership) { create(:membership, :member, project: project, user: user) }

      it 'displays project with client information' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Website Project (Acme Corp)')
      end

      it 'formats client information in parentheses' do
        response = dispatch_command :projects

        expect(response.first[:text]).to match(/• Website Project \(Acme Corp\)/)
      end
    end

    context 'user as owner' do
      let!(:project1) { create(:project, name: 'Owner Project 1') }
      let!(:project2) { create(:project, name: 'Owner Project 2') }
      let!(:membership1) { create(:membership, :owner, project: project1, user: user) }
      let!(:membership2) { create(:membership, :owner, project: project2, user: user) }

      it 'displays all owned projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Owner Project 1')
        expect(response.first[:text]).to include('Owner Project 2')
      end
    end

    context 'user as member' do
      let!(:member_project) { create(:project, name: 'Member Project') }
      let!(:owner_project) { create(:project, name: 'Other Owner Project') }
      let!(:member_membership) { create(:membership, :member, project: member_project, user: user) }
      let!(:owner_membership) { create(:membership, :owner, project: owner_project, user: create(:user)) }

      it 'displays only projects where user is member' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Member Project')
        expect(response.first[:text]).not_to include('Other Owner Project')
      end
    end

    context 'user as viewer' do
      let!(:viewer_project) { create(:project, name: 'Viewer Project') }
      let!(:viewer_membership) { create(:membership, :viewer, project: viewer_project, user: user) }

      it 'displays projects where user is viewer' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Viewer Project')
      end
    end

    context 'mixed project access' do
      let!(:owned_project) { create(:project, name: 'My Project') }
      let!(:member_project) { create(:project, name: 'Team Project') }
      let!(:viewer_project) { create(:project, name: 'Monitor Project') }
      let!(:client) { create(:client, name: 'Client Co') }

      before do
        create(:membership, :owner, project: owned_project, user: user)
        create(:membership, :member, project: member_project, user: user)
        create(:membership, :viewer, project: viewer_project, user: user)

        # Добавляем клиент к одному из проектов
        member_project.update!(client: client)
      end

      it 'displays all accessible projects regardless of role' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('My Project')
        expect(response.first[:text]).to include('Team Project (Client Co)')
        expect(response.first[:text]).to include('Monitor Project')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds with empty projects message' do
      response = dispatch_command :projects

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Доступные проекты:')
      expect(response.first[:text]).to include('У вас пока нет проектов.')
    end
  end

  context 'archived projects' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    let!(:active_project) { create(:project, :with_owner, name: 'Active Project') }
    let!(:archived_project) { create(:project, :with_owner, name: 'Archived Project', archived_at: 1.day.ago) }
    let!(:active_membership) { create(:membership, :member, project: active_project, user: user) }
    let!(:archived_membership) { create(:membership, :member, project: archived_project, user: user) }

    it 'displays only active (non-archived) projects' do
      response = dispatch_command :projects

      expect(response.first[:text]).to include('Active Project')
      expect(response.first[:text]).not_to include('Archived Project')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование отображения проектов
2. Тестирование пустого списка проектов
3. Тестирование проектов с клиентами

### Средний приоритет
1. Тестирование для разных ролей (owner/member/viewer)
2. Тестирование фильтрации архивных проектов

### Низкий приоритет
1. Сложные сценарии смешанного доступа
2. Тестирование форматирования

## Необходимые моки и фикстуры

### Fixed fixtures
- Стандартные фикстуры пользователей, проектов, клиентов
- Фабрики для создания membership с разными ролями

### Dynamic mocks
- Минимальное количество моков, фокус на реальных данных

## Ожидаемые результаты
- Полное покрытие логики команды ProjectsCommand
- Уверенность в корректном отображении проектов для всех ролей
- Правильная фильтрация и форматирование списка проектов
- Стабильность при работе с различными состояниями проектов

## Примечания
- ProjectsCommand часто используется пользователями для навигации
- Важно тестировать реальное поведение фильтрации alive проектов
- Форматирование критически важно для пользовательского опыта