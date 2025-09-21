# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::AdduserCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
  end

  describe '#call' do
    context 'when project_slug is not provided' do
      context 'when user has manageable projects' do
        let!(:project) { create(:project, name: 'Test Project') }

        before do
          # Create ownership membership
          create(:membership, :owner, user: user, project: project)
        end

        it 'shows project selection' do
          command.call

          expect(controller).to have_received(:save_context).with(:adduser_project_callback_query)
          expect(controller).to have_received(:respond_with).with(
            :message,
            text: 'Выберите проект, в который хотите добавить пользователя:',
            reply_markup: hash_including(:inline_keyboard)
          )
        end
      end

      context 'when user has no manageable projects' do
        it 'responds with no projects message' do
          command.call

          expect(controller).to have_received(:respond_with)
            .with(:message, text: 'У вас нет проектов, в которые можно добавить пользователей')
        end
      end
    end

    context 'when project_slug is provided but username is not' do
      it 'asks for username' do
        command.call('test_project')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Укажите никнейм пользователя (например: @username или username)')
      end
    end

    context 'when both project_slug and username are provided' do
      let(:project_manager) { instance_double(TelegramProjectManager) }

      before do
        allow(TelegramProjectManager).to receive(:new).with(user, controller: controller).and_return(project_manager)
        allow(project_manager).to receive(:add_user_to_project)
      end

      it 'delegates to TelegramProjectManager' do
        command.call('test_project', 'username', 'member')

        expect(TelegramProjectManager).to have_received(:new).with(user, controller: controller)
        expect(project_manager).to have_received(:add_user_to_project)
          .with('test_project', 'username', 'member')
      end
    end
  end
end
