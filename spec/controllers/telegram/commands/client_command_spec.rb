# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::ClientCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:client) { create(:client, user: user, key: 'test_client', name: 'Test Client') }
  let(:project) { create(:project, name: 'Test Project', slug: 'test-project') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:multiline) { |*args| args.compact.join("\n") }
    # Create a session hash that we can modify
    session_data = {}
    # Simple session stub - no and_wrap_original needed
    allow(controller).to receive(:session).and_return(session_data)
    allow(controller).to receive(:find_project) { |slug| Project.find_by(slug: slug) }
    allow(controller).to receive(:t) { |key, options = {}| I18n.t(key, **options) }
    # Mock can_update? method for edit operations
    allow(user).to receive(:can_update?).and_return(true)
  end

  describe '#call' do
    context 'without arguments' do
      context 'when user has clients' do
        let!(:client1) { create(:client, user: user, key: 'client1', name: 'Client One') }
        let!(:client2) { create(:client, user: user, key: 'client2', name: 'Client Two') }

        it 'shows list of user clients' do
          command.call

          expect(controller).to have_received(:respond_with).with(:message, text: kind_of(String))
          expect(controller).to have_received(:multiline).with(
            I18n.t('telegram.commands.client.list_title'),
            nil
          )
        end
      end

      context 'when user has no clients' do
        it 'shows empty message' do
          command.call

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.list_empty')
          )
        end
      end
    end

    context 'with help command' do
      it 'shows help message' do
        command.call('help')

        expect(controller).to have_received(:respond_with).with(:message, text: kind_of(String))
      end
    end

    context 'with add command' do
      it 'prompts for client name' do
        command.call('add')

        expect(controller).to have_received(:save_context).with(:add_client_name)
        expect(controller).to have_received(:respond_with).with(
          :message,
          text: I18n.t('telegram.commands.client.add_prompt_name')
        )
      end
    end

    context 'with show command' do
      context 'when client exists and user has access' do
        before { client }

        it 'shows client information' do
          command.call('show', 'test_client')

          expect(controller).to have_received(:respond_with).with(:message, text: kind_of(String))
        end
      end

      context 'when client does not exist' do
        it 'shows not found error' do
          command.call('show', 'nonexistent')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.show_not_found', key: 'nonexistent')
          )
        end
      end
    end

    context 'with edit command' do
      context 'when client exists and user is owner' do
        before { client }

        it 'prompts for new name' do
          command.call('edit', 'test_client')

          expect(controller).to have_received(:save_context).with(:edit_client_name)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.edit_prompt_name')
          )
        end
      end

      context 'when client does not exist' do
        it 'shows not found error' do
          command.call('edit', 'nonexistent')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.edit_not_found', key: 'nonexistent')
          )
        end
      end
    end

    context 'with delete command' do
      context 'when client exists and user is owner' do
        before { client }

        it 'shows confirmation prompt' do
          command.call('delete', 'test_client')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: kind_of(String)
          )
        end
      end

      context 'when client does not exist' do
        it 'shows not found error' do
          command.call('delete', 'nonexistent')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.delete_not_found', key: 'nonexistent')
          )
        end
      end
    end

    context 'with projects command' do
      let!(:project) { create(:project, client: client) }

      before do
        create(:membership, user: user, project: project)
      end

      it 'shows client projects' do
        command.call('projects', 'test_client')

        expect(controller).to have_received(:respond_with).with(:message, text: kind_of(String))
      end
    end

    context 'with attach command' do
      let!(:project) { create(:project, slug: 'test-project') }

      before do
        create(:membership, user: user, project: project)
      end

      it 'attaches project to client' do
        command.call('attach', 'test_client', 'test-project')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: kind_of(String)
        )
      end
    end

    context 'with detach command' do
      let!(:project) { create(:project, client: client, slug: 'test-project') }

      before do
        create(:membership, user: user, project: project)
      end

      it 'detaches project from client' do
        command.call('detach', 'test_client', 'test-project')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: kind_of(String)
        )
      end
    end

    context 'with invalid command' do
      it 'shows usage error' do
        command.call('invalid_command')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: I18n.t('telegram.commands.client.usage_error')
        )
      end
    end
  end

  describe 'context handlers' do
    describe '#add_client_name' do
      context 'with valid name' do
        it 'saves name and prompts for key' do
          command.send(:add_client_name, 'Valid Company Name')

          expect(controller).to have_received(:save_context).with(:add_client_key)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.add_prompt_key')
          )
        end
      end

      context 'with invalid name' do
        it 'shows error and reprompts' do
          command.send(:add_client_name, '')

          expect(controller).to have_received(:save_context).with(:add_client_name)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.name_invalid')
          )
        end
      end
    end

    describe '#add_client_key' do
      let(:session_with_name) { { client_name: 'Test Company' } }

      before do
        allow(controller).to receive(:session).and_return(session_with_name)
      end

      context 'with valid key' do
        it 'creates client and shows success' do
          command.send(:add_client_key, 'test_key')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: kind_of(String)
          )
        end
      end

      context 'with invalid key' do
        it 'shows error and reprompts' do
          command.send(:add_client_key, 'Invalid Key!')

          expect(controller).to have_received(:save_context).with(:add_client_key)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.key_invalid', key: 'invalid key!')
          )
        end
      end

      context 'with duplicate key' do
        let!(:existing_client) { create(:client, user: user, key: 'existing_key') }

        it 'shows error and reprompts' do
          command.send(:add_client_key, 'existing_key')

          expect(controller).to have_received(:save_context).with(:add_client_key)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.key_exists', key: 'existing_key')
          )
        end
      end
    end

    describe '#edit_client_name' do
      let(:session_with_key) { { edit_client_key: 'test_client' } }

      before do
        allow(controller).to receive(:session).and_return(session_with_key)
        client
      end

      context 'with valid name' do
        it 'updates client and shows success' do
          command.send(:edit_client_name, 'Updated Name')

          expect(controller).to have_received(:respond_with).with(
            :message,
            text: kind_of(String)
          )
        end
      end

      context 'with invalid name' do
        it 'shows error and reprompts' do
          command.send(:edit_client_name, '')

          expect(controller).to have_received(:save_context).with(:edit_client_name)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: I18n.t('telegram.commands.client.name_invalid')
          )
        end
      end
    end
  end
end
