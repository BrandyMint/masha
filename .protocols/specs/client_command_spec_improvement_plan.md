# План улучшения спецификаций для client_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `ClientCommand` имеет базовое покрытие, но команда реализует сложную систему управления клиентами с множеством подкоманд, контекстными методами и проверками прав доступа. Требует комплексного тестирования всех функций.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет функциональность
- Отсутствует тестирование подкоманд (add, show, edit, delete, projects, attach, detach)
- Не проверяются контекстные методы для создания и редактирования клиентов
- Нет тестирования валидации ключей и имен клиентов
- Отсутствует тестирование прав доступа на разные операции
- Не проверяется привязка/отвязка проектов к клиентам

## Стратегия реализации по итерациям

### 🎯 **Итерация 1: Базовый функционал (15-20 тестов)**
**Цель:** Покрыть самые используемые функции

**Что тестируем:**
1. Список клиентов (пустой и с данными)
2. Основные подкоманды (show, help)
3. Запуск процесса создания клиента

### 🎯 **Итерация 2: CRUD операции (10-15 тестов)**
**Цель:** Добавить полноценное управление клиентами

**Что тестируем:**
1. Полный workflow создания клиента
2. Редактирование клиентов
3. Удаление клиентов

### 🎯 **Итерация 3: Работа с проектами (10-12 тестов)**
**Цель:** Тестировать интеграцию с проектами

**Что тестируем:**
1. Привязка/отвязка проектов
2. Список проектов клиента
3. Edge cases и права доступа

---

## Итерация 1: Базовый функционал

### Структура спека

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

    context 'client list functionality' do
      it 'shows empty list message when no clients' do
        response = dispatch_command :client

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Нет клиентов')
      end

      context 'with existing clients' do
        let!(:client1) { create(:client, user: user, name: 'Client One', key: 'client1') }
        let!(:client2) { create(:client, user: user, name: 'Client Two', key: 'client2') }
        let!(:project) { create(:project, :with_owner, client: client1) }

        it 'shows clients list with projects count' do
          response = dispatch_command :client

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Client One')
          expect(response.first[:text]).to include('Client Two')
          expect(response.first[:text]).to include('1 проект')
          expect(response.first[:text]).to include('0 проектов')
        end

        it 'formats list items correctly with keys' do
          response = dispatch_command :client

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('client1')
          expect(response.first[:text]).to include('client2')
        end
      end
    end

    context 'client subcommands' do
      let!(:client) { create(:client, user: user, name: 'Test Client', key: 'testclient') }
      let!(:project) { create(:project, :with_owner) }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      context 'client show' do
        it 'shows client information' do
          response = dispatch_command :client, 'show', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Test Client')
          expect(response.first[:text]).to include('testclient')
        end

        it 'shows client with projects' do
          project.update!(client: client)

          response = dispatch_command :client, 'show', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include(project.name)
          expect(response.first[:text]).to include('1 проект')
        end

        it 'handles non-existent client' do
          response = dispatch_command :client, 'show', 'nonexistent'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('не найден')
        end

        it 'requires client key parameter' do
          response = dispatch_command :client, 'show'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Использование')
        end
      end

      context 'client help' do
        it 'shows help information' do
          response = dispatch_command :client, 'help'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Команды управления')
        end
      end

      context 'invalid subcommand' do
        it 'shows usage error for unknown command' do
          response = dispatch_command :client, 'invalid', 'param'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Использование')
        end
      end
    end

    context 'client creation workflow' do
      context 'add_client_name' do
        it 'starts client creation process' do
          response = dispatch_command :client, 'add'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Введите имя клиента')
        end

        it 'rejects empty client name' do
          response = dispatch_message ''

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('некорректное имя')
        end

        it 'accepts valid client name' do
          dispatch_command :client

          response = dispatch_message 'New Client Name'

          expect(response).not_to be_nil
          expect(response[:text]).to include('Введите ключ')
        end

        it 'rejects too long client name' do
          dispatch_command :client

          response = dispatch_message 'a' * 300

          expect(response).not_to be_nil
          expect(response[:text]).to include('некорректное имя')
        end
      end

      context 'add_client_key' do
        before do
          # Запускаем процесс создания клиента
          dispatch_command :client
          dispatch_message 'Test Client Name'
        end

        it 'accepts valid client key and creates client' do
          expect {
            response = dispatch_message 'testkey123'
          }.to change(Client, :count).by(1)

          expect(response).not_to be_nil
          expect(response[:text]).to include('Клиент добавлен')
          expect(Client.find_by(key: 'testkey123')).not_to be_nil
        end

        it 'rejects empty client key' do
          response = dispatch_message ''

          expect(response).not_to be_nil
          expect(response[:text]).to include('некорректный ключ')
        end

        it 'rejects invalid client key format' do
          response = dispatch_message 'invalid@key'

          expect(response).not_to be_nil
          expect(response[:text]).to include('некорректный ключ')
        end

        it 'rejects duplicate client key' do
          existing_client = create(:client, user: user, key: 'existing')

          response = dispatch_message 'existing'

          expect(response).not_to be_nil
          expect(response[:text]).to include('уже существует')
        end
      end
    end

    context 'access control' do
      let(:other_user) { create(:user, :with_telegram) }
      let!(:client) { create(:client, user: other_user, name: 'Other Client', key: 'otherclient') }

      it 'prevents showing other user client' do
        response = dispatch_command :client, 'show', 'otherclient'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не найден')
      end

      it 'prevents editing other user client' do
        response = dispatch_command :client, 'edit', 'otherclient'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не найден')
      end

      it 'prevents deleting other user client' do
        response = dispatch_command :client, 'delete', 'otherclient'

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('не найден')
      end
    end

    context 'without projects' do
      it 'shows client list with no projects' do
        client = create(:client, user: user, name: 'Test Client', key: 'testclient')
        response = dispatch_command :client

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('0 проектов')
      end
    end

    context 'edge cases' do
      it 'handles client name with special characters' do
        dispatch_command :client

        response = dispatch_message 'Client "Special" & Test'

        expect(response).not_to be_nil
        expect(response).to be_truthy
      end

      it 'handles client key with underscores and hyphens' do
        dispatch_command :client
        dispatch_message 'Test Client'

        response = dispatch_message 'test_key-123'

        expect(response).not_to be_nil
        expect(response[:text]).to include('Клиент добавлен')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows empty clients list' do
      response = dispatch_command :client

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Нет клиентов')
    end

    it 'shows access denied for client operations' do
      response = dispatch_command :client, 'show', 'test'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('не найден')
    end

    it 'shows help for unauthenticated user' do
      response = dispatch_command :client, 'help'

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Команды управления')
    end
  end
end
```

## Итерация 2: CRUD операции

### Дополнительные тесты для Итерации 2

```ruby
# Добавить в существующий spec

    context 'client editing workflow' do
      let!(:client) { create(:client, user: user, name: 'Original Name', key: 'testclient') }

      context 'client edit' do
        it 'starts edit process for valid client' do
          response = dispatch_command :client, 'edit', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Введите новое имя')
        end

        it 'updates client name successfully' do
          dispatch_command :client, 'edit', 'testclient'

          response = dispatch_message 'Updated Name'

          expect(response).not_to be_nil
          expect(response[:text]).to include('Имя изменено')
          expect(client.reload.name).to eq('Updated Name')
        end

        it 'rejects empty name during edit' do
          dispatch_command :client, 'edit', 'testclient'

          response = dispatch_message ''

          expect(response).not_to be_nil
          expect(response[:text]).to include('некорректное имя')
        end
      end

      context 'client delete' do
        it 'requires confirmation for deletion' do
          response = dispatch_command :client, 'delete', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Подтвердите удаление')
          expect(response.first[:text]).to include('Test Client')
        end

        it 'deletes client with confirmation' do
          expect {
            response = dispatch_command :client, 'delete', 'testclient', 'confirm'
          }.to change(Client, :count).by(-1)

          expect(response).not_to be_nil
          expect(response[:text]).to include('Клиент удален')
          expect(Client.find_by(key: 'testclient')).to be_nil
        end

        it 'prevents deletion with linked projects' do
          project.update!(client: client)

          response = dispatch_command :client, 'delete', 'testclient', 'confirm'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('связанные проекты')
          expect(Client.find_by(key: 'testclient')).not_to be_nil
        end
      end
    end
```

## Итерация 3: Работа с проектами

### Дополнительные тесты для Итерации 3

```ruby
# Добавить в существующий spec

      context 'client projects' do
        it 'shows empty projects list' do
          response = dispatch_command :client, 'projects', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Нет проектов')
        end

        it 'shows projects list' do
          project.update!(client: client)

          response = dispatch_command :client, 'projects', 'testclient'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include(project.name)
          expect(response.first[:text]).to include('Проекты клиента Test Client')
        end
      end

      context 'client attach' do
        it 'attaches project to client' do
          response = dispatch_command :client, 'attach', 'testclient', project.slug

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Привязан проект')
          expect(project.reload.client).to eq(client)
        end

        it 'handles non-existent project' do
          response = dispatch_command :client, 'attach', 'testclient', 'nonexistent'

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('не найден')
        end

        it 'prevents attaching non-member project' do
          # Создаем проект, где пользователь не состоит
          other_project = create(:project, :with_owner)

          response = dispatch_command :client, 'attach', 'testclient', other_project.slug

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('не найден')
        end
      end

      context 'client detach' do
        before do
          project.update!(client: client)
        end

        it 'detaches project from client' do
          response = dispatch_command :client, 'detach', 'testclient', project.slug

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('Отвязан проект')
          expect(project.reload.client).to be_nil
        end

        it 'handles project not attached to client' do
          other_client = create(:client, user: user, key: 'otherclient')
          response = dispatch_command :client, 'detach', 'otherclient', project.slug

          expect(response).not_to be_nil
          expect(response.first[:text]).to include('не найден')
        end
      end
```

## Приоритеты реализации

### **Итерация 1 (15-20 тестов) - Критический приоритет**
1. Тестирование списка клиентов
2. Основные подкоманды (show, help)
3. Базовый workflow создания клиента
4. Проверка прав доступа

### **Итерация 2 (10-15 тестов) - Высокий приоритет**
1. Полный workflow создания клиента
2. Редактирование клиентов
3. Удаление клиентов
4. Валидация данных

### **Итерация 3 (10-12 тестов) - Средний приоритет**
1. Привязка/отвязка проектов
2. Список проектов клиента
3. Дополнительные edge cases

## Необходимые фикстуры

### Fixed fixtures
```ruby
# Нужно добавить в factories.rb или использовать существующие
FactoryBot.define do
  factory :client do
    name { "Test Client #{sequence}" }
    key { "client#{sequence}" }
    user
  end
end
```

## Ожидаемые результаты по итерациям

### **После Итерации 1:**
- Базовое покрытие самых используемых функций
- Уверенность в корректной работе списка клиентов
- Понимание workflow создания клиента

### **После Итерации 2:**
- Полное CRUD управление клиентами
- Уверенность в валидации данных
- Корректная обработка ошибок

### **После Итерации 3:**
- Полная интеграция с проектами
- Комплексная проверка прав доступа
- Готовый к production тест

## Примечания по адаптации

### **Ключевые изменения из оригинального плана:**
1. ✅ Убраны прямые вызовы `controller.send()`
2. ✅ Использованы `dispatch_message` для контекстных методов
3. ✅ Уменьшен объем с ~50 до ~37 тестов
4. ✅ Структурировано по итерациям
5. ✅ Следует паттернам из `new_command_spec.rb`

### **Рекомендации:**
- Реализовывать строго по итерациям
- Проверять каждый тест перед переходом к следующему
- Добавлять дополнительные тесты только при необходимости

Этот адаптированный план обеспечивает реалистичный объем работ при сохранении качества покрытия.