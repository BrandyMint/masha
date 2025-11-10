# План улучшения спецификаций для rename_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `RenameCommand` имеет базовое покрытие, но команда реализует сложный workflow переименования проектов с двумя режимами: прямое переименование и интерактивный режим с выбором проекта, подтверждением и callback queries.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет функциональность
- Отсутствует тестирование прямого переименования проекта
- Не проверяется интерактивный режим с выбором проекта
- Нет тестирования callback queries для подтверждения
- Отсутствует тестирование сессии и контекстных методов
- Не проверяется валидация прав доступа

## План улучшения

### 1. Тестирование прямого переименования
**Цель**: Проверить прямое переименование проекта
- Успешное переименование с валидными параметрами
- Обработка несуществующего проекта
- Валидация прав доступа на переименование
- Обработка некорректного имени проекта

### 2. Тестирование интерактивного режима
**Цель**: Проверить workflow с выбором проекта
- Показ списка доступных проектов для переименования
- Форматирование списка с slug в скобках
- Обработка случая без доступных проектов

### 3. Тестирование контекстных методов
**Цель**: Полное покрытие всех этапов интерактивного переименования
- `rename_project_callback_query` - выбор проекта
- `rename_new_name_input` - ввод нового имени
- `rename_confirm_callback_query` - подтверждение/отмена

### 4. Тестирование сессии и состояния
**Цель**: Проверить корректную работу сессии
- Сохранение project_id в сессии
- Сохранение new_name в сессии
- Очистка сессии после завершения
- Обработка ошибок сессии

### 5. Тестирование прав доступа
**Цель**: Убедиться в корректной проверке прав
- Owner может переименовывать проект
- Member не может переименовывать проект
- Viewer не может переименовывать проект

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

    context 'direct rename functionality' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'renames project successfully with valid parameters' do
        response = dispatch_command :rename, project.slug, 'New Project Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('переименован')
      end

      it 'handles project not found for direct rename' do
        response = dispatch_command :rename, 'nonexistent', 'New Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Проект не найден')
      end

      it 'handles empty new name for direct rename' do
        response = dispatch_command :rename, project.slug, ''

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('введите название')
      end

      it 'handles special characters in project name' do
        response = dispatch_command :rename, project.slug, 'Проект "Новый" & Тестовый'

        expect(response).not_to be_nil
      end

      it 'handles very long project name' do
        long_name = 'Very Long Project Name ' * 10
        response = dispatch_command :rename, project.slug, long_name

        expect(response).not_to be_nil
      end
    end

    context 'interactive mode - project selection' do
      let!(:project1) { create(:project, name: 'Web Project', slug: 'web-project') }
      let!(:project2) { create(:project, name: 'Mobile App', slug: 'mobile-app') }

      before do
        create(:membership, :owner, project: project1, user: user)
        create(:membership, :owner, project: project2, user: user)
      end

      it 'shows project selection list when called without arguments' do
        response = dispatch_command :rename

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')
        expect(response.first[:text]).to include('Web Project (web-project)')
        expect(response.first[:text]).to include('Mobile App (mobile-app)')
      end

      it 'includes inline keyboard with project options' do
        response = dispatch_command :rename

        expect(response).not_to be_nil
        keyboard = response.first[:reply_markup][:inline_keyboard]
        expect(keyboard).not_to be_empty

        project_buttons = keyboard.flatten
        expect(project_buttons.map { |btn| btn[:text] }).to include('Web Project (web-project)')
        expect(project_buttons.map { |btn| btn[:callback_data] }).to include('rename_project:web-project')
      end

      it 'shows no manageable projects message when user has no projects' do
        # Удаляем все проекты пользователя
        user.memberships.destroy_all

        response = dispatch_command :rename

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Нет проектов')
      end
    end

    context 'context methods testing' do
      let!(:project) { create(:project, name: 'Test Project', slug: 'test-project') }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      context 'rename_project_callback_query' do
        it 'handles project selection with valid project' do
          expect {
            controller.send(:rename_project_callback_query, project.slug)
          }.not_to raise_error
        end

        it 'sets up session for new name input' do
          controller.send(:rename_project_callback_query, project.slug)

          expect(controller.session[:context]).to eq(:rename_new_name_input)
        end

        it 'handles non-existent project in callback' do
          expect {
            controller.send(:rename_project_callback_query, 'nonexistent')
          }.not_to raise_error
        end
      end

      context 'rename_new_name_input' do
        before do
          # Устанавливаем сессию как при выборе проекта
          controller.session[:telegram_session] = { 'project_id' => project.id }
        end

        it 'handles valid new name input' do
          expect {
            controller.send(:rename_new_name_input, 'New Project Name')
          }.not_to raise_error
        end

        it 'shows confirmation message with new name' do
          response = controller.send(:rename_new_name_input, 'New Project Name')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Test Project')
          expect(response[:text]).to include('New Project Name')
        end

        it 'includes confirmation buttons' do
          response = controller.send(:rename_new_name_input, 'New Project Name')

          expect(response[:reply_markup]).not_to be_nil
          keyboard = response[:reply_markup][:inline_keyboard]
          expect(keyboard.flatten.map { |btn| btn[:text] }).to include('✅ Да, переименовать')
          expect(keyboard.flatten.map { |btn| btn[:callback_data] }).to include('rename_confirm:save')
        end

        it 'handles empty new name' do
          response = controller.send(:rename_new_name_input, '')

          expect(response).not_to be_nil
          expect(response[:text]).to include('название не может быть пустым')
        end

        it 'handles session corruption' do
          controller.session[:telegram_session] = { 'project_id' => 99999 }

          response = controller.send(:rename_new_name_input, 'New Name')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Проект не найден')
        end
      end

      context 'rename_confirm_callback_query' do
        before do
          # Устанавливаем полную сессию для подтверждения
          controller.session[:telegram_session] = {
            'project_id' => project.id,
            'new_name' => 'New Project Name'
          }
        end

        it 'handles confirmation with save action' do
          expect {
            controller.send(:rename_confirm_callback_query, 'save')
          }.not_to raise_error
        end

        it 'handles cancellation' do
          response = controller.send(:rename_confirm_callback_query, 'cancel')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Переименование отменено')
        end

        it 'clears session after confirmation' do
          controller.send(:rename_confirm_callback_query, 'save')

          expect(controller.session[:telegram_session]).to be_nil
        end

        it 'clears session after cancellation' do
          controller.send(:rename_confirm_callback_query, 'cancel')

          expect(controller.session[:telegram_session]).to be_nil
        end
      end
    end

    context 'access control' do
      let!(:project) { create(:project, :with_owner) }
      let!(:other_project) { create(:project, :with_owner) }

      it 'allows owner to rename project' do
        create(:membership, :owner, project: project, user: user)

        response = dispatch_command :rename, project.slug, 'New Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).not_to include('доступно только владельцу')
      end

      it 'denies member from renaming project' do
        create(:membership, :member, project: project, user: user)

        response = dispatch_command :rename, project.slug, 'New Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступно только владельцу')
      end

      it 'denies viewer from renaming project' do
        create(:membership, :viewer, project: project, user: user)

        response = dispatch_command :rename, project.slug, 'New Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('доступно только владельцу')
      end

      it 'denies member from seeing project in selection list' do
        create(:membership, :member, project: project, user: user)
        owner_project = create(:project, name: 'Owner Project')
        create(:membership, :owner, project: owner_project, user: user)

        response = dispatch_command :rename

        expect(response.first[:text]).to include('Owner Project')
        expect(response.first[:text]).not_to include(project.name)
      end
    end

    context 'without projects' do
      it 'shows no manageable projects message' do
        response = dispatch_command :rename

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Нет проектов')
      end

      it 'handles direct rename with no projects' do
        response = dispatch_command :rename, 'nonexistent', 'New Name'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Проект не найден')
      end
    end

    context 'session edge cases' do
      let!(:project) { create(:project, :with_owner) }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      it 'handles missing telegram session in new name input' do
        controller.session.delete(:telegram_session)

        response = controller.send(:rename_new_name_input, 'New Name')

        expect(response).not_to be_nil
        expect(response[:text]).to include('Проект не найден')
      end

      it 'handles corrupted project_id in session' do
        controller.session[:telegram_session] = { 'project_id' => 'invalid' }

        response = controller.send(:rename_new_name_input, 'New Name')

        expect(response).not_to be_nil
        expect(response[:text]).to include('Проект не найден')
      end

      it 'handles missing new_name in confirmation' do
        controller.session[:telegram_session] = { 'project_id' => project.id }

        response = controller.send(:rename_confirm_callback_query, 'save')

        expect(response).not_to be_nil
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows no manageable projects message' do
      response = dispatch_command :rename

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Нет проектов')
    end

    it 'handles direct rename attempt' do
      response = dispatch_command :rename, 'project-slug', 'New Name'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Проект не найден')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование прямого переименования проекта
2. Тестирование интерактивного режима с выбором проекта
3. Тестирование контекстных методов для workflow

### Средний приоритет
1. Тестирование прав доступа для разных ролей
2. Тестирование управления сессией
3. Обработка ошибок и edge cases

### Низкий приоритет
1. Тестирование интеграции с ProjectRenameService
2. Сложные edge cases сессии

## Необходимые моки и фикстуры

### Fixed fixtures
- Фикстуры пользователей, проектов, memberships
- Telegram webhook контекст
- RenameConfig константы

### Dynamic mocks
- `ProjectRenameService` - для изоляции бизнес-логики
- Контроллер и сессия для тестирования состояний

## Ожидаемые результаты
- Полное покрытие workflow переименования проектов
- Уверенность в корректной работе сессии и контекстов
- Стабильность при работе с различными правами доступа
- Четкая документация двух режимов команды через тесты

## Примечания
- RenameCommand имеет сложную архитектуру с двумя режимами работы
- Критически важно тестировать сессию и контекстные методы
- ProjectRenameService содержит бизнес-логику, которую нужно изолировать
- Callback queries требуют специального подхода к тестированию