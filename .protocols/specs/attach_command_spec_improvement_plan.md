# План улучшения спецификаций для attach_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `AttachCommand` имеет базовое покрытие, но команда выполняет важную функцию привязки Telegram чата к проекту. Требует более детального тестирования различных сценариев и состояний чата.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет фактическую функциональность
- Отсутствует проверка обновления telegram_chat_id у проекта
- Не проверяется различие между чатами и личными сообщениями
- Нет тестирования прав доступа на привязку чата
- Отсутствует тестирование различных состояний проекта

## План улучшения

### 1. Тестирование привязки чата к проекту
**Цель**: Проверить корректное обновление telegram_chat_id
- Успешная привязка чата к проекту
- Проверка обновления поля telegram_chat_id в базе данных
- Корректное сообщение об успешной привязке

### 2. Тестирование валидации чата
**Цель**: Убедиться в корректной обработке типов чатов
- Различение чатов (group/supergroup) от личных сообщений
- Отклонение личных сообщений с правильным сообщением
- Работа с разными типами чат ID (отрицательные для чатов)

### 3. Тестирование параметров
**Цель**: Проверить корректную обработку входных параметров
- Отсутствие project_slug
- Некорректный project_slug
- Существующий и несуществующий проекты

### 4. Тестирование прав доступа
**Цель**: Убедиться в проверке прав на привязку чата
- Owner может привязывать чат
- Member может привязывать чат
- Viewer не может привязывать чат
- Попытка привязки к чужому проекту

### 5. Тестирование состояний проекта
**Цель**: Проверить работу с проектами в разных состояниях
- Проект без telegram_chat_id
- Проект с уже существующим telegram_chat_id
- Архивные проекты

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

    context 'with existing projects' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'owner') }

      it 'shows proper message when no project specified' do
        response = dispatch_command :attach

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Укажите первым аргументом проект')
      end

      it 'does not return nil response for missing project' do
        response = dispatch_command :attach

        expect(response).not_to be_nil
        expect(response.first).not_to be_nil
      end
    end

    context 'attaching chat to project' do
      let!(:project) { create(:project, name: 'Test Project', slug: 'test-project') }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      before do
        # Эмулируем чат (group chat имеет отрицательный ID)
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })
      end

      it 'attaches chat successfully to project' do
        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include("Установили этот чат основным в проекте #{project.name}")
      end

      it 'updates project telegram_chat_id in database' do
        expect {
          dispatch_command :attach, project.slug
        }.to change { project.reload.telegram_chat_id }.from(nil).to(-123456789)
      end

      it 'handles project not found gracefully' do
        response = dispatch_command :attach, 'nonexistent-project'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end

      it 'updates existing telegram_chat_id' do
        # Устанавливаем существующий chat_id
        project.update!(telegram_chat_id: -987654321)

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
        expect(project.reload.telegram_chat_id).to eq(-123456789)
      end
    end

    context 'chat type validation' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'rejects personal chat (positive chat_id)' do
        allow(controller).to receive(:chat).and_return({ 'id' => 123456789, 'type' => 'private' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Присоединять можно только чаты')
        expect(response.first[:text]).to include('личную переписку нельзя')
      end

      it 'accepts group chat (negative chat_id)' do
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
      end

      it 'accepts supergroup chat (negative chat_id)' do
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'supergroup' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
      end

      it 'accepts channel chat (negative chat_id)' do
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'channel' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
      end
    end

    context 'access control' do
      let!(:project) { create(:project, :with_owner) }

      before do
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })
      end

      it 'allows owner to attach chat' do
        create(:membership, :owner, project: project, user: user)

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
      end

      it 'allows member to attach chat' do
        create(:membership, :member, project: project, user: user)

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Установили этот чат основным')
      end

      it 'denies viewer from attaching chat' do
        create(:membership, :viewer, project: project, user: user)

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступ')
      end

      it 'denies non-member from attaching chat' do
        # Не создаем membership для пользователя

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end
    end

    context 'multiple projects' do
      let!(:project1) { create(:project, name: 'Project One', slug: 'project-one') }
      let!(:project2) { create(:project, name: 'Project Two', slug: 'project-two') }

      before do
        create(:membership, :owner, project: project1, user: user)
        create(:membership, :owner, project: project2, user: user)
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })
      end

      it 'attaches chat to first project' do
        response = dispatch_command :attach, project1.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Project One')
        expect(project1.reload.telegram_chat_id).to eq(-123456789)
      end

      it 'attaches chat to second project' do
        response = dispatch_command :attach, project2.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Project Two')
        expect(project2.reload.telegram_chat_id).to eq(-123456789)
      end

      it 'can reattach chat to different project' do
        # Сначала привязываем к первому проекту
        dispatch_command :attach, project1.slug
        expect(project1.reload.telegram_chat_id).to eq(-123456789)

        # Затем привязываем ко второму
        response = dispatch_command :attach, project2.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Project Two')
        expect(project2.reload.telegram_chat_id).to eq(-123456789)
        # Первый проект должен остаться с прежним chat_id
        expect(project1.reload.telegram_chat_id).to eq(-123456789)
      end
    end

    context 'without projects' do
      it 'shows access message for non-existent project' do
        response = dispatch_command :attach, 'nonexistent'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект не найден')
      end

      it 'shows parameter required message' do
        response = dispatch_command :attach

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Укажите первым аргументом проект')
      end
    end

    context 'archived projects' do
      let!(:archived_project) { create(:project, :with_owner, archived_at: 1.day.ago) }
      let!(:membership) { create(:membership, :owner, project: archived_project, user: user) }

      before do
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })
      end

      it 'handles archived project gracefully' do
        response = dispatch_command :attach, archived_project.slug

        expect(response).not_to be_nil
        # archived_project не должен быть найден через find_project
        expect(response.first[:text]).to include('проект не найден')
      end
    end

    context 'edge cases' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'handles very large negative chat_id' do
        allow(controller).to receive(:chat).and_return({ 'id' => -999999999999999999, 'type' => 'supergroup' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(project.reload.telegram_chat_id).to eq(-999999999999999999)
      end

      it 'handles zero chat_id edge case' do
        allow(controller).to receive(:chat).and_return({ 'id' => 0, 'type' => 'private' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Присоединять можно только чаты')
      end

      it 'handles project name with special characters' do
        project.update!(name: 'Project "Test" & Development')
        allow(controller).to receive(:chat).and_return({ 'id' => -123456789, 'type' => 'group' })

        response = dispatch_command :attach, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Project "Test" & Development')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows parameter required message' do
      response = dispatch_command :attach

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Укажите первым аргументом проект')
    end

    it 'handles project attachment attempt' do
      response = dispatch_command :attach, 'some-project'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('проект не найден')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование успешной привязки чата к проекту
2. Проверка обновления telegram_chat_id в базе данных
3. Валидация типа чата (chat vs личное сообщение)

### Средний приоритет
1. Тестирование прав доступа для разных ролей
2. Обработка различных состояний проекта
3. Валидация параметров

### Низкий приоритет
1. Edge cases с большими chat_id
2. Специальные символы в названиях проектов

## Необходимые моки и фикстуры

### Fixed fixtures
- Фикстуры пользователей, проектов, memberships
- Telegram webhook контекст

### Dynamic mocks
- Мокирование `controller.chat` для эмуляции разных типов чатов
- Возможно мокирование `find_project` для тестирования ошибок

## Ожидаемые результаты
- Полное покрытие логики привязки чата к проекту
- Уверенность в корректной работе с разными типами чатов
- Стабильность при проверке прав доступа
- Четкая документация поведения команды через тесты

## Примечания
- AttachCommand относительно простая, но критически важная команда
- Важно правильно эмулировать различные типы чатов (group/supergroup vs private)
- telegram_chat_id является ключевым полем для интеграции с Telegram
- Права доступа должны соответствовать бизнес-логике проекта