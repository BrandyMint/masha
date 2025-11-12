# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated regular user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'responds to /users command without errors' do
      expect { dispatch_command :users }.not_to raise_error
    end

    it 'shows project users when user has projects' do
      # Проверяем что команда показывает пользователей проекта
      expect { dispatch_command :users }.not_to raise_error
    end

    context 'with projects' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'shows project users list' do
        response = dispatch_command :users
        expect(response).not_to be_nil
      end

      it 'responds to /users help without errors' do
        expect { dispatch_command :users, 'help' }.not_to raise_error
      end

      it 'shows help text with available commands' do
        response = dispatch_command :users, 'help'
        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Управление пользователями')
      end
    end

    context 'users add subcommand' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /users add without errors' do
        expect { dispatch_command :users, 'add' }.not_to raise_error
      end

      it 'shows project selection for add command' do
        response = dispatch_command :users, 'add'
        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите проект')
      end

      it 'adds user directly with parameters' do
        expect do
          dispatch_command :users, 'add', project.slug, 'test_new_user', 'member'
        end.to change(Membership, :count).by(1)
      end

      it 'handles username with @ symbol' do
        expect do
          dispatch_command :users, 'add', project.slug, '@test_at_user', 'member'
        end.to change(Membership, :count).by(1)
      end

      it 'shows error when username not specified' do
        response = dispatch_command :users, 'add', project.slug
        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Укажите никнейм')
      end
    end

    context 'users remove subcommand' do
      it 'responds to /users remove without errors' do
        expect { dispatch_command :users, 'remove' }.not_to raise_error
      end

      it 'shows not implemented message' do
        response = dispatch_command :users, 'remove', 'test_project', 'test_user'
        expect(response).not_to be_nil
        expect(response.first[:text]).to include('пока не реализована')
      end
    end

    context 'users list subcommand' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /users list without errors' do
        expect { dispatch_command :users, 'list' }.not_to raise_error
      end
    end
  end

  context 'authenticated developer user' do
    let(:developer_telegram_id) { ApplicationConfig.developer_telegram_id }
    let(:user) { users(:admin) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { developer_telegram_id }

    include_context 'authenticated user'

    it 'responds to /users all command without errors for developer' do
      expect { dispatch_command :users, 'all' }.not_to raise_error
    end

    it 'shows all users list for developer' do
      users(:telegram_clean_user)
      users(:telegram_empty_user)

      response = dispatch_command :users, 'all'
      expect(response).not_to be_nil
    end

    it 'handles user list generation for developer' do
      users(:telegram_clean_user)
      users(:telegram_empty_user)

      expect { dispatch_command :users }.not_to raise_error
    end
  end

  context 'unauthenticated user' do
    it 'responds to /users command without errors' do
      expect { dispatch_command :users }.not_to raise_error
    end

    it 'responds to /users help without errors' do
      expect { dispatch_command :users, 'help' }.not_to raise_error
    end
  end

  context 'unknown subcommand' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'handles unknown subcommand gracefully' do
      response = dispatch_command :users, 'unknown'
      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Неизвестная подкоманда')
    end
  end
end
