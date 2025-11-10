# План улучшения спецификаций для adduser_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `AdduserCommand` имеет базовое покрытие, но команда реализует сложный workflow добавления пользователей в проекты с двумя режимами: прямое добавление и интерактивный режим с выбором проекта, роли и callback queries.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет функциональность
- Отсутствует тестирование прямого добавления пользователя
- Не проверяется интерактивный режим с выбором проекта
- Нет тестирования callback queries для выбора роли
- Отсутствует тестирование сессии и контекстных методов
- Не проверяется валидация прав доступа и форматов username

## План улучшения

### 1. Тестирование прямого добавления пользователя
**Цель**: Проверить прямое добавление пользователя в проект
- Успешное добавление с валидными параметрами
- Валидация обязательных параметров (project_slug, username)
- Поддержка разных ролей (owner, member, viewer)
- Обработка username с @ и без @

### 2. Тестирование интерактивного режима
**Цель**: Проверить workflow с выбором проекта
- Показ списка проектов, которыми управляет пользователь
- Форматирование списка проектов
- Обработка случая без управляемых проектов

### 3. Тестирование контекстных методов
**Цель**: Полное покрытие всех этапов интерактивного добавления
- `adduser_project_callback_query` - выбор проекта
- `adduser_username_input` - ввод username пользователя
- `adduser_role_callback_query` - выбор роли пользователя

### 4. Тестирование сессии и состояния
**Цель**: Проверить корректную работу сессии
- Сохранение project_slug в сессии
- Сохранение username в сессии
- Очистка сессии после завершения
- Обработка ошибок сессии

### 5. Тестирование прав доступа
**Цель**: Убедиться в корректной проверке прав
- Owner может добавлять пользователей
- Member не может добавлять пользователей
- Viewer не может добавлять пользователей

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

    let(:target_user) { create(:user, :with_telegram, username: 'newuser') }

    context 'direct user addition' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'adds user successfully with all parameters' do
        expect {
          dispatch_command :adduser, project.slug, 'newuser', 'member'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.project).to eq(project)
        expect(new_membership.user).to eq(target_user)
        expect(new_membership.role_cd).to eq(1) # member role
      end

      it 'adds user with owner role' do
        expect {
          dispatch_command :adduser, project.slug, 'newuser', 'owner'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(0) # owner role
      end

      it 'adds user with viewer role' do
        expect {
          dispatch_command :adduser, project.slug, 'newuser', 'viewer'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(2) # viewer role
      end

      it 'adds user with default member role when role not specified' do
        expect {
          dispatch_command :adduser, project.slug, 'newuser'
        }.to change(Membership, :count).by(1)

        new_membership = Membership.last
        expect(new_membership.role_cd).to eq(1) # member role
      end

      it 'handles username with @ symbol' do
        expect {
          dispatch_command :adduser, project.slug, '@newuser'
        }.to change(Membership, :count).by(1)

        expect(Membership.last.user).to eq(target_user)
      end

      it 'handles username without @ symbol' do
        expect {
          dispatch_command :adduser, project.slug, 'newuser'
        }.to change(Membership, :count).by(1)

        expect(Membership.last.user).to eq(target_user)
      end

      it 'shows error message when project not specified' do
        response = dispatch_command :adduser

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')
      end

      it 'shows error message when username not specified' do
        response = dispatch_command :adduser, project.slug

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Укажите никнейм пользователя')
      end

      it 'handles non-existent project' do
        response = dispatch_command :adduser, 'nonexistent', 'newuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
      end

      it 'handles non-existent user' do
        response = dispatch_command :adduser, project.slug, 'nonexistentuser'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
      end

      it 'handles duplicate membership gracefully' do
        # Создаем существующее членство
        create(:membership, project: project, user: target_user, role: :member)

        response = dispatch_command :adduser, project.slug, 'newuser'

        expect(response).not_to be_nil
        # Не должно создавать новую запись
        expect(Membership.where(project: project, user: target_user).count).to eq(1)
      end
    end

    context 'interactive mode - project selection' do
      let!(:project1) { create(:project, name: 'Web Project', slug: 'web-project') }
      let!(:project2) { create(:project, name: 'Mobile App', slug: 'mobile-app') }

      before do
        create(:membership, :owner, project: project1, user: user)
        create(:membership, :owner, project: project2, user: user)
      end

      it 'shows manageable projects list when called without arguments' do
        response = dispatch_command :adduser

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')
        expect(response.first[:text]).to include('Web Project')
        expect(response.first[:text]).to include('Mobile App')
      end

      it 'includes inline keyboard with project options' do
        response = dispatch_command :adduser

        expect(response).not_to be_nil
        keyboard = response.first[:reply_markup][:inline_keyboard]
        expect(keyboard).not_to be_empty

        project_buttons = keyboard.flatten
        expect(project_buttons.map { |btn| btn[:text] }).to include('Web Project')
        expect(project_buttons.map { |btn| btn[:callback_data] }).to include('adduser_project:web-project')
      end

      it 'sets up context for project callback query' do
        dispatch_command :adduser

        expect(controller.session[:context]).to eq(:adduser_project_callback_query)
      end

      it 'shows no manageable projects message when user has no projects' do
        # Удаляем все проекты пользователя
        user.memberships.destroy_all

        response = dispatch_command :adduser

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('У вас нет проектов')
      end
    end

    context 'context methods testing' do
      let!(:project) { create(:project, name: 'Test Project', slug: 'test-project') }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      context 'adduser_project_callback_query' do
        it 'handles project selection with valid project' do
          expect {
            controller.send(:adduser_project_callback_query, project.slug)
          }.not_to raise_error
        end

        it 'sets up session for username input' do
          controller.send(:adduser_project_callback_query, project.slug)

          expect(controller.session[:context]).to eq(:adduser_username_input)
        end

        it 'includes project name in username prompt' do
          response = controller.send(:adduser_project_callback_query, project.slug)

          expect(response[:text]).to include("Проект: #{project.name}")
          expect(response[:text]).to include('введите никнейм пользователя')
        end

        it 'handles non-existent project in callback' do
          response = controller.send(:adduser_project_callback_query, 'nonexistent')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Проект не найден')
        end

        it 'denies access for non-owner' do
          member_project = create(:project, name: 'Member Project')
          create(:membership, :member, project: member_project, user: user)

          response = controller.send(:adduser_project_callback_query, member_project.slug)

          expect(response).not_to be_nil
          expect(response[:text]).to include('У вас нет прав')
        end
      end

      context 'adduser_username_input' do
        before do
          # Устанавливаем сессию как при выборе проекта
          controller.session[:telegram_session] = { 'project_slug' => project.slug }
        end

        it 'handles valid username input' do
          expect {
            controller.send(:adduser_username_input, 'newuser')
          }.not_to raise_error
        end

        it 'shows role selection with username' do
          response = controller.send(:adduser_username_input, 'testuser')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Пользователь: @testuser')
          expect(response[:text]).to include('Выберите роль')
        end

        it 'includes role selection buttons' do
          response = controller.send(:adduser_username_input, 'testuser')

          expect(response[:reply_markup]).not_to be_nil
          keyboard = response[:reply_markup][:inline_keyboard]
          expect(keyboard.flatten.map { |btn| btn[:text] }).to include('Владелец (owner)')
          expect(keyboard.flatten.map { |btn| btn[:callback_data] }).to include('adduser_role:owner')
        end

        it 'removes @ symbol from username' do
          controller.send(:adduser_username_input, '@testuser')

          expect(controller.telegram_session['username']).to eq('testuser')
        end

        it 'sets up context for role callback query' do
          controller.send(:adduser_username_input, 'testuser')

          expect(controller.session[:context]).to eq(:adduser_role_callback_query)
        end
      end

      context 'adduser_role_callback_query' do
        before do
          # Устанавливаем полную сессию для выбора роли
          controller.session[:telegram_session] = {
            'project_slug' => project.slug,
            'username' => 'testuser'
          }
        end

        it 'handles role selection and adds user' do
          expect {
            controller.send(:adduser_role_callback_query, 'member')
          }.to change(Membership, :count).by(1)
        end

        it 'cleans session after role selection' do
          controller.send(:adduser_role_callback_query, 'member')

          expect(controller.session[:telegram_session]).to be_nil
        end

        it 'shows processing message' do
          response = controller.send(:adduser_role_callback_query, 'member')

          expect(response).not_to be_nil
          expect(response[:text]).to include('Добавляем пользователя @testuser')
          expect(response[:text]).to include('проект test-project')
          expect(response[:text]).to include('роль member')
        end

        it 'handles owner role' do
          expect {
            controller.send(:adduser_role_callback_query, 'owner')
          }.to change(Membership, :count).by(1)

          new_membership = Membership.last
          expect(new_membership.role_cd).to eq(0) # owner role
        end

        it 'handles viewer role' do
          expect {
            controller.send(:adduser_role_callback_query, 'viewer')
          }.to change(Membership, :count).by(1)

          new_membership = Membership.last
          expect(new_membership.role_cd).to eq(2) # viewer role
        end
      end
    end

    context 'access control' do
      let!(:project) { create(:project, :with_owner) }

      it 'allows owner to add users' do
        create(:membership, :owner, project: project, user: user)

        expect {
          dispatch_command :adduser, project.slug, 'newuser', 'member'
        }.to change(Membership, :count).by(1)
      end

      it 'denies member from adding users' do
        create(:membership, :member, project: project, user: user)

        response = dispatch_command :adduser, project.slug, 'newuser', 'member'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
        expect(Membership.count).not_to change
      end

      it 'denies viewer from adding users' do
        create(:membership, :viewer, project: project, user: user)

        response = dispatch_command :adduser, project.slug, 'newuser', 'member'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
        expect(Membership.count).not_to change
      end

      it 'denies non-member from adding users' do
        # Не создаем membership для пользователя

        response = dispatch_command :adduser, project.slug, 'newuser', 'member'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
        expect(Membership.count).not_to change
      end
    end

    context 'without projects' do
      it 'shows no manageable projects message' do
        response = dispatch_command :adduser

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('У вас нет проектов')
      end

      it 'handles direct add with no projects' do
        response = dispatch_command :adduser, 'project-slug', 'username'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не удалось')
      end
    end

    context 'session edge cases' do
      let!(:project) { create(:project, :with_owner) }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      it 'handles missing telegram session in username input' do
        controller.session.delete(:telegram_session)

        response = controller.send(:adduser_username_input, 'testuser')

        expect(response).not_to be_nil
      end

      it 'handles missing session data in role callback' do
        controller.session[:telegram_session] = {}

        response = controller.send(:adduser_role_callback_query, 'member')

        expect(response).not_to be_nil
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows no manageable projects message' do
      response = dispatch_command :adduser

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('У вас нет проектов')
    end

    it 'handles direct add attempt' do
      response = dispatch_command :adduser, 'project-slug', 'username', 'member'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('не удалось')
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование прямого добавления пользователя
2. Тестирование интерактивного режима с выбором проекта
3. Тестирование контекстных методов для workflow

### Средний приоритет
1. Тестирование прав доступа для разных ролей
2. Тестирование управления сессией
3. Обработка различных форматов username

### Низкий приоритет
1. Тестирование интеграции с TelegramProjectManager
2. Edge cases сессии

## Необходимые моки и фикстуры

### Fixed fixtures
- Фикстуры пользователей с username
- Фикстуры проектов и memberships
- Telegram webhook контекст

### Dynamic mocks
- `TelegramProjectManager` - для изоляции бизнес-логики
- Контроллер и сессия для тестирования состояний

## Ожидаемые результаты
- Полное покрытие workflow добавления пользователей
- Уверенность в корректной работе сессии и контекстов
- Стабильность при работе с различными правами доступа
- Четкая документация двух режимов команды через тесты

## Примечания
- AdduserCommand имеет сложную архитектуру с двумя режимами работы
- Критически важно тестировать сессию и контекстные методы
- TelegramProjectManager содержит бизнес-логику, которую нужно изолировать
- Права доступа должны строго соответствовать роли owner для добавления пользователей