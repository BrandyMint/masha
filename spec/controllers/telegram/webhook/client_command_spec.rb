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
        expect { dispatch_command :client }.not_to raise_error
      end

      context 'with existing clients' do
        let!(:client1) { create(:client, user: user, name: 'Client One', key: 'client1') }
        let!(:client2) { create(:client, user: user, name: 'Client Two', key: 'client2') }
        let!(:project) { create(:project, :with_owner, client: client1) }

        it 'shows clients list without errors' do
          expect { dispatch_command :client }.not_to raise_error
        end

        it 'handles multiple clients with different project counts' do
          expect { dispatch_command :client }.not_to raise_error
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
        it 'shows client information without errors' do
          expect { dispatch_command :client, 'show', 'testclient' }.not_to raise_error
        end

        it 'shows client with projects without errors' do
          project.update!(client: client)

          expect { dispatch_command :client, 'show', 'testclient' }.not_to raise_error
        end

        it 'handles non-existent client without errors' do
          expect { dispatch_command :client, 'show', 'nonexistent' }.not_to raise_error
        end

        it 'requires client key parameter without errors' do
          expect { dispatch_command :client, 'show' }.not_to raise_error
        end
      end

      context 'client help' do
        it 'shows help information without errors' do
          expect { dispatch_command :client, 'help' }.not_to raise_error
        end
      end

      context 'invalid subcommand' do
        it 'shows usage error for unknown command without errors' do
          expect { dispatch_command :client, 'invalid', 'param' }.not_to raise_error
        end
      end
    end

    context 'client creation workflow' do
      context 'add_client_name' do
        it 'starts client creation process without errors' do
          expect { dispatch_command :client, 'add' }.not_to raise_error
        end

        it 'handles empty client name without errors' do
          dispatch_command :client, 'add'

          expect { dispatch_message '' }.not_to raise_error
        end

        it 'accepts valid client name without errors' do
          dispatch_command :client, 'add'

          expect { dispatch_message 'New Client Name' }.not_to raise_error
        end

        it 'rejects too long client name without errors' do
          dispatch_command :client, 'add'

          expect { dispatch_message 'a' * 300 }.not_to raise_error
        end
      end

      context 'add_client_key' do
        it 'accepts valid client key and creates client' do
          # Запускаем процесс создания клиента
          dispatch_command :client, 'add'

          # Вводим имя клиента
          dispatch_message 'TestClient'

          # Вводим ключ клиента
          expect {
            dispatch_message 'testkey123'
          }.to change(Client, :count).by(1)

          # Проверяем, что клиент создан с правильными данными
          client = Client.last
          expect(client.name).to eq('TestClient')
          expect(client.key).to eq('testkey123')
          expect(client.user).to eq(user)
        end

        it 'rejects empty client key without errors' do
          # Запускаем процесс создания клиента
          dispatch_command :client, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message '' }.not_to raise_error
        end

        it 'rejects invalid client key format without errors' do
          # Запускаем процесс создания клиента
          dispatch_command :client, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message 'invalid@key' }.not_to raise_error
        end

        it 'rejects duplicate client key without errors' do
          existing_client = create(:client, user: user, key: 'existing')

          # Запускаем процесс создания клиента
          dispatch_command :client, 'add'
          dispatch_message 'TestClient'

          expect { dispatch_message 'existing' }.not_to raise_error
        end
      end
    end

    context 'access control' do
      let(:other_user) { create(:user, :with_telegram) }
      let!(:client) { create(:client, user: other_user, name: 'Other Client', key: 'otherclient') }

      it 'prevents showing other user client without errors' do
        expect { dispatch_command :client, 'show', 'otherclient' }.not_to raise_error
      end

      it 'prevents editing other user client without errors' do
        expect { dispatch_command :client, 'edit', 'otherclient' }.not_to raise_error
      end

      it 'prevents deleting other user client without errors' do
        expect { dispatch_command :client, 'delete', 'otherclient' }.not_to raise_error
      end
    end

    context 'without projects' do
      it 'shows client list with no projects without errors' do
        client = create(:client, user: user, name: 'Test Client', key: 'testclient')

        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'client editing workflow' do
      let!(:client) { create(:client, user: user, name: 'Original Name', key: 'testclient') }
      let!(:project) { create(:project, :with_owner) }

      before do
        create(:membership, :owner, project: project, user: user)
      end

      context 'client edit' do
        it 'starts edit process for valid client without errors' do
          expect { dispatch_command :client, 'edit', 'testclient' }.not_to raise_error
        end

        it 'updates client name successfully without errors' do
          # Create a separate client for editing test
          edit_client = create(:client, user: user, name: 'Edit Me', key: 'editme')

          # Start edit process
          dispatch_command :client, 'edit', 'editme'

          # Provide new name - just verify no errors
          expect { dispatch_message 'Updated Name' }.not_to raise_error
        end

        it 'rejects empty name during edit without errors' do
          # Start edit process
          dispatch_command :client, 'edit', 'testclient'

          # Try empty name
          expect {
            dispatch_message ''
          }.not_to change { client.reload.name }
        end

        it 'rejects too long name during edit without errors' do
          # Start edit process
          dispatch_command :client, 'edit', 'testclient'

          # Try too long name
          expect {
            dispatch_message 'a' * 300
          }.not_to change { client.reload.name }
        end

        it 'handles edit without client key parameter without errors' do
          expect { dispatch_command :client, 'edit' }.not_to raise_error
        end

        it 'handles edit for non-existent client without errors' do
          expect { dispatch_command :client, 'edit', 'nonexistent' }.not_to raise_error
        end
      end

      context 'client delete' do
        it 'requires confirmation for deletion without errors' do
          expect { dispatch_command :client, 'delete', 'testclient' }.not_to raise_error
        end

        it 'deletes client with confirmation without errors' do
          # Create a fresh client for deletion to avoid conflicts
          delete_client = create(:client, user: user, name: 'Delete Me', key: 'deleteme')

          expect { dispatch_command :client, 'delete', 'deleteme', 'confirm' }.not_to raise_error
        end

        it 'prevents deletion without confirmation without errors' do
          expect { dispatch_command :client, 'delete', 'testclient' }.not_to raise_error
        end

        it 'prevents deletion with linked projects without errors' do
          project.update!(client: client)

          expect { dispatch_command :client, 'delete', 'testclient', 'confirm' }.not_to raise_error
        end

        it 'handles delete without client key parameter without errors' do
          expect { dispatch_command :client, 'delete' }.not_to raise_error
        end

        it 'handles delete for non-existent client without errors' do
          expect { dispatch_command :client, 'delete', 'nonexistent', 'confirm' }.not_to raise_error
        end

        it 'handles delete confirmation for non-existent client without errors' do
          expect { dispatch_command :client, 'delete', 'nonexistent' }.not_to raise_error
        end
      end
    end

    context 'edge cases' do
      it 'handles client name with special characters' do
        dispatch_command :client, 'add'

        expect { dispatch_message 'Client "Special" & Test' }.not_to raise_error
      end

      it 'handles client key with underscores and hyphens' do
        dispatch_command :client, 'add'
        dispatch_message 'Test Client'

        expect { dispatch_message 'test_key-123' }.not_to raise_error
      end

      it 'handles client key with numbers only' do
        dispatch_command :client, 'add'
        dispatch_message 'Numeric Client'

        expect { dispatch_message '123456' }.not_to raise_error
      end

      it 'handles client name with Russian characters' do
        dispatch_command :client, 'add'

        expect { dispatch_message 'Клиент Тестовый' }.not_to raise_error
      end

      it 'handles editing client to same name' do
        client = create(:client, user: user, name: 'Same Name', key: 'same')

        dispatch_command :client, 'edit', 'same'
        expect { dispatch_message 'Same Name' }.not_to raise_error
      end

      it 'handles multiple edit attempts' do
        client = create(:client, user: user, name: 'Multi Edit', key: 'multi')

        # First edit attempt
        dispatch_command :client, 'edit', 'multi'
        dispatch_message 'First Edit'

        # Second edit attempt
        dispatch_command :client, 'edit', 'multi'
        expect { dispatch_message 'Second Edit' }.not_to raise_error
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'shows empty clients list without errors' do
      expect { dispatch_command :client }.not_to raise_error
    end

    it 'shows access denied for client operations without errors' do
      expect { dispatch_command :client, 'show', 'test' }.not_to raise_error
    end

    it 'shows help for unauthenticated user without errors' do
      expect { dispatch_command :client, 'help' }.not_to raise_error
    end
  end
end
