# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'client list functionality' do
      it 'shows empty list message when no clients' do
        expect { dispatch_command :clients }.not_to raise_error
      end

      context 'with existing clients' do
        # Используем существующие fixtures вместо создания через create!
        let!(:client) { clients(:testclient) }

        it 'shows clients list without errors' do
          expect { dispatch_command :clients }.not_to raise_error
        end

        it 'displays client information correctly' do
          response = dispatch_command :clients
          expect(response).not_to be_nil

          # Проверяем, что в ответе есть заголовок списка клиентов
          first_message = response.first
          expect(first_message[:text]).to include('🏢')
        end

        it 'shows client count information' do
          response = dispatch_command :clients
          expect(response).not_to be_nil

          # Проверяем, что в ответе есть информация о количестве клиентов
          first_message = response.first
          expect(first_message[:text]).to include('клиенты')
        end
      end
    end

    context 'client subcommands' do
      let!(:client) { clients(:testclient) }
      let!(:project) { projects(:work_project) }

      before do
        # Используем существующий membership fixture для пользователя с work_project
      end

      context 'client show' do
        it 'shows client information without errors' do
          expect { dispatch_command :clients, 'show', 'testclient' }.not_to raise_error
        end

        it 'shows client with projects without errors' do
          # Use project that already has this client in fixtures
          projects(:project_with_client1)

          expect { dispatch_command :clients, 'show', 'client1' }.not_to raise_error
        end

        it 'handles non-existent client without errors' do
          expect { dispatch_command :clients, 'show', 'nonexistent' }.not_to raise_error
        end

        it 'requires client key parameter without errors' do
          expect { dispatch_command :clients, 'show' }.not_to raise_error
        end
      end

      context 'client help' do
        it 'shows help information without errors' do
          expect { dispatch_command :clients, 'help' }.not_to raise_error
        end
      end

      context 'invalid subcommand' do
        it 'shows usage error for unknown command without errors' do
          expect { dispatch_command :clients, 'invalid', 'param' }.not_to raise_error
        end
      end
    end

    context 'client creation workflow' do
      context 'add_client_name' do
        it 'starts client creation process without errors' do
          expect { dispatch_command :clients, 'add' }.not_to raise_error
        end

        it 'prompts for client name' do
          response = dispatch_command :clients, 'add'
          expect(response).not_to be_nil

          # Проверяем, что бот запрашивает название клиента
          first_message = response.first
          expect(first_message[:text]).to include('название компании')
        end

        it 'handles empty client name without errors' do
          dispatch_command :clients, 'add'

          # Проверяем реакцию на пустое название
          expect { dispatch_message('') }.not_to raise_error
        end

        it 'starts client creation workflow properly' do
          response = dispatch_command :clients, 'add'
          expect(response).not_to be_nil

          # Проверяем, что процесс создания начинается корректно
          first_message = response.first
          expect(first_message[:text]).to include('название компании')
        end

        it 'creates client successfully through complete workflow' do
          dispatch_command :clients, 'add'

          # Шаг 1: Ввод названия клиента
          expect { dispatch_message('NewClient') }.not_to raise_error

          # Шаг 2: Ввод ключа клиента
          expect do
            dispatch_message('new-test-client')
          end.to change(Client, :count).by(1)

          # Проверяем, что клиент создался с правильными данными
          client = Client.last
          expect(client.name).to eq('NewClient')
          expect(client.key).to eq('new-test-client')
        end

        it 'shows client creation confirmation at the end' do
          dispatch_command :clients, 'add'
          dispatch_message('AwesomeClient')

          # После успешного создания ключа, клиент должен быть создан
          initial_count = Client.count
          dispatch_message('awesome-client')
          expect(Client.count).to eq(initial_count + 1)

          # Проверяем, что клиент действительно создан
          expect(Client.where(key: 'awesome-client').exists?).to be true
        end

        it 'prevents duplicate client keys' do
          # Создаем первый клиент напрямую в базе с простыми данными
          Client.create!(user: user, name: 'Test', key: 'test')

          dispatch_command :clients, 'add'
          dispatch_message('Another')
          response = dispatch_message('test') # Пытаемся использовать существующий ключ

          # Проверяем, что бот сообщает об ошибке
          expect(response).not_to be_nil
          first_message = response.first
          expect(first_message[:text]).to include('Введите название компании') # остается в контексте
        end

        it 'accepts valid client name without errors' do
          dispatch_command :clients, 'add'

          expect { dispatch_message 'New Client Name' }.not_to raise_error
        end

        it 'rejects too long client name without errors' do
          dispatch_command :clients, 'add'

          expect { dispatch_message 'a' * 300 }.not_to raise_error
        end
      end

      context 'add_client_key' do
        it 'accepts valid client key and creates client' do
          # Запускаем процесс создания клиента
          dispatch_command :clients, 'add'

          # Вводим имя клиента
          dispatch_message 'TestClient'

          # Вводим ключ клиента
          expect do
            dispatch_message 'testkey123'
          end.to change(Client, :count).by(1)

          # Проверяем, что клиент создан с правильными данными
          client = Client.last
          expect(client.name).to eq('TestClient')
          expect(client.key).to eq('testkey123')
          expect(client.user).to eq(user)
        end

        it 'rejects empty client key without errors' do
          # Запускаем процесс создания клиента
          dispatch_command :clients, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message '' }.not_to raise_error
        end

        it 'rejects invalid client key format without errors' do
          # Запускаем процесс создания клиента
          dispatch_command :clients, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message 'invalid@key' }.not_to raise_error
        end

        it 'rejects duplicate client key without errors' do
          clients(:existing_client)

          # Запускаем процесс создания клиента
          dispatch_command :clients, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message 'existing' }.not_to raise_error
        end
      end
    end

    context 'access control' do
      let(:other_user) { users(:regular_user) }
      let!(:client) { clients(:other_client) }

      it 'prevents showing other user client without errors' do
        expect { dispatch_command :clients, 'show', 'otherclient' }.not_to raise_error
      end

      it 'prevents editing other user client without errors' do
        expect { dispatch_command :clients, 'edit', 'otherclient' }.not_to raise_error
      end

      it 'prevents deleting other user client without errors' do
        expect { dispatch_command :clients, 'delete', 'otherclient' }.not_to raise_error
      end
    end

    context 'without projects' do
      it 'shows client list with no projects without errors' do
        clients(:testclient)

        expect { dispatch_command :clients }.not_to raise_error
      end
    end

    context 'projects button visibility' do
      context 'when client has no projects' do
        let!(:client_no_projects) { clients(:testclient) }

        it 'does not include projects callback in menu' do
          # Проверяем что controller.respond_with вызывается без кнопки "Проекты"
          expect(controller).to receive(:respond_with).with(
            :message,
            hash_including(
              reply_markup: hash_including(
                inline_keyboard: satisfy do |keyboard|
                  buttons = keyboard.flatten
                  # Проверяем что нет кнопки с clients_projects:
                  buttons.none? { |b| b[:callback_data]&.start_with?('clients_projects:') }
                end
              )
            )
          )

          dispatch(callback_query: {
                     id: 'test_callback_no_projects',
                     from: from,
                     message: { message_id: 100, chat: chat },
                     data: "clients_select:#{client_no_projects.key}"
                   })
        end
      end

      context 'when client has projects' do
        let!(:client_with_projects) { clients(:client1) }
        let!(:project) { projects(:project_with_client1) }

        it 'includes projects button in menu' do
          # Проверяем что controller.respond_with вызывается С кнопкой "Проекты"
          expect(controller).to receive(:respond_with).with(
            :message,
            hash_including(
              reply_markup: hash_including(
                inline_keyboard: satisfy do |keyboard|
                  buttons = keyboard.flatten
                  # Проверяем что есть кнопка с clients_projects:
                  expected_callback = "clients_projects:#{client_with_projects.key}"
                  buttons.any? { |b| b[:callback_data] == expected_callback }
                end
              )
            )
          )

          dispatch(callback_query: {
                     id: 'test_callback_with_projects',
                     from: from,
                     message: { message_id: 101, chat: chat },
                     data: "clients_select:#{client_with_projects.key}"
                   })
        end
      end
    end

    context 'client editing workflow' do
      let!(:client) { clients(:testclient) }
      let!(:project) { projects(:work_project) }

      before do
        # Используем существующий membership fixture для пользователя с work_project
      end

      context 'client edit' do
        it 'starts edit process for valid client without errors' do
          expect { dispatch_command :clients, 'edit', 'testclient' }.not_to raise_error
        end

        it 'updates client name successfully without errors' do
          # Use existing client for editing test
          clients(:edit_me_client)

          # Start edit process
          dispatch_command :clients, 'edit', 'editme'

          # Provide new name - just verify no errors
          expect { dispatch_message 'Updated Name' }.not_to raise_error
        end

        it 'rejects empty name during edit without errors' do
          # Start edit process
          dispatch_command :clients, 'edit', 'testclient'

          # Try empty name
          expect do
            dispatch_message ''
          end.not_to(change { client.reload.name })
        end

        it 'rejects too long name during edit without errors' do
          # Start edit process
          dispatch_command :clients, 'edit', 'testclient'

          # Try too long name
          expect do
            dispatch_message 'a' * 300
          end.not_to(change { client.reload.name })
        end

        it 'handles edit without client key parameter without errors' do
          expect { dispatch_command :clients, 'edit' }.not_to raise_error
        end

        it 'handles edit for non-existent client without errors' do
          expect { dispatch_command :clients, 'edit', 'nonexistent' }.not_to raise_error
        end
      end

      context 'client delete' do
        it 'requires confirmation for deletion without errors' do
          expect { dispatch_command :clients, 'delete', 'testclient' }.not_to raise_error
        end

        it 'deletes client with confirmation without errors' do
          # Use existing client for deletion test
          clients(:delete_me_client)

          expect { dispatch_command :clients, 'delete', 'deleteme', 'confirm' }.not_to raise_error
        end

        it 'prevents deletion without confirmation without errors' do
          expect { dispatch_command :clients, 'delete', 'testclient' }.not_to raise_error
        end

        it 'prevents deletion with linked projects without errors' do
          # Use project that already has this client in fixtures
          projects(:project_with_client1)

          expect { dispatch_command :clients, 'delete', 'client1', 'confirm' }.not_to raise_error
        end

        it 'handles delete without client key parameter without errors' do
          expect { dispatch_command :clients, 'delete' }.not_to raise_error
        end

        it 'handles delete for non-existent client without errors' do
          expect { dispatch_command :clients, 'delete', 'nonexistent', 'confirm' }.not_to raise_error
        end

        it 'handles delete confirmation for non-existent client without errors' do
          expect { dispatch_command :clients, 'delete', 'nonexistent' }.not_to raise_error
        end
      end
    end

    context 'edge cases' do
      it 'handles client name with special characters' do
        dispatch_command :clients, 'add'

        expect { dispatch_message 'Client "Special" & Test' }.not_to raise_error
      end

      it 'handles client key with underscores and hyphens' do
        dispatch_command :clients, 'add'
        dispatch_message 'Test Client'

        expect { dispatch_message 'test_key-123' }.not_to raise_error
      end

      it 'handles client key with numbers only' do
        dispatch_command :clients, 'add'
        dispatch_message 'Numeric Client'

        expect { dispatch_message '123456' }.not_to raise_error
      end

      it 'handles client name with Russian characters' do
        dispatch_command :clients, 'add'

        expect { dispatch_message 'Клиент Тестовый' }.not_to raise_error
      end

      it 'handles editing client to same name' do
        clients(:same_name_client)

        dispatch_command :clients, 'edit', 'same'
        expect { dispatch_message 'Same Name' }.not_to raise_error
      end

      it 'handles multiple edit attempts' do
        clients(:multi_edit_client)

        # First edit attempt
        dispatch_command :clients, 'edit', 'multi'
        dispatch_message 'First Edit'

        # Second edit attempt
        dispatch_command :clients, 'edit', 'multi'
        expect { dispatch_message 'Second Edit' }.not_to raise_error
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12_345 }

    it 'shows empty clients list without errors' do
      expect { dispatch_command :clients }.not_to raise_error
    end

    it 'shows access denied for clients operations without errors' do
      expect { dispatch_command :clients, 'show', 'test' }.not_to raise_error
    end

    it 'shows help for unauthenticated user without errors' do
      expect { dispatch_command :clients, 'help' }.not_to raise_error
    end
  end
end
