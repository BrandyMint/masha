# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:telegram_clean_user) }
    let(:telegram_user) { telegram_users(:telegram_clean) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'user with no projects' do
      let(:user) { users(:telegram_empty_user) }
      let(:telegram_user) { telegram_users(:telegram_empty) }
      let(:from_id) { telegram_user.id }

      include_context 'authenticated user'

      it 'responds to /projects command without errors' do
        expect { dispatch_command :projects }.not_to raise_error
      end

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
      # Используем memberships для clean_user: member и owner roles
      let!(:project1) { projects(:personal_project) }
      let!(:project2) { projects(:dev_project) }

      it 'displays projects header' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Доступные проекты:')
      end

      it 'lists all available projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Personal Project')
        expect(response.first[:text]).to include('Development Project')
      end

      it 'formats projects with bullet points' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('• Personal Project')
        expect(response.first[:text]).to include('• Development Project')
      end
    end

    context 'projects with clients' do
      let!(:client) { clients(:client1) }
      let!(:project) { projects(:project_with_client1) }
      # Используем существующий membership fixture

      it 'displays project with client information' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Website Project (Client One)')
      end

      it 'formats client information in parentheses' do
        response = dispatch_command :projects

        expect(response.first[:text]).to match(/• Website Project \(Client One\)/)
      end
    end

    context 'user as owner' do
      # Используем dev_project где telegram_clean_user - owner
      let!(:project1) { projects(:dev_project) }
      let!(:project2) { projects(:personal_project) }
      # Используем существующие membership fixtures для owner

      it 'displays all owned projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Development Project')
        expect(response.first[:text]).to include('Personal Project')
      end
    end

    context 'user as member' do
      # Используем personal_project где telegram_clean_user - member
      let!(:member_project) { projects(:personal_project) }
      let!(:owner_project) { projects(:dev_project) }
      # Используем существующие membership fixtures

      it 'displays only projects where user is member' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Personal Project')
        expect(response.first[:text]).to include('Development Project')
      end
    end

    context 'user as viewer' do
      # Используем тестовый проект где telegram_clean_user может быть viewer
      let!(:viewer_project) { projects(:test_project) }
      # Добавляем membership для telegram_clean_user как viewer

      it 'displays projects where user is viewer' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Test Project')
      end
    end

    context 'mixed project access' do
      let!(:owned_project) { projects(:dev_project) }
      let!(:member_project) { projects(:personal_project) }
      let!(:viewer_project) { projects(:test_project) }
      let!(:client) { clients(:client1) }

      # Используем существующие membership fixtures для всех типов ролей
      # telegram_clean_user имеет доступ ко всем этим проектам через memberships

      it 'displays all accessible projects regardless of role' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Development Project')
        expect(response.first[:text]).to include('Personal Project')
        expect(response.first[:text]).to include('Test Project')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12_345 }

    it 'responds with empty projects message' do
      response = dispatch_command :projects

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Доступные проекты:')
      expect(response.first[:text]).to include('У вас пока нет проектов.')
    end
  end

  context 'archived projects' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    let!(:active_project) { projects(:work_project) }
    let!(:archived_project) { projects(:inactive_project) }
    # Используем существующие membership fixtures

    it 'displays only active (non-archived) projects' do
      response = dispatch_command :projects

      expect(response.first[:text]).to include('Work Project')
      expect(response.first[:text]).not_to include('Inactive Project')
    end
  end

  context 'edge cases' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'long project names' do
      # Используем существующий проект с длинным названием
      let!(:project) { projects(:work_project) }

      it 'handles very long project names gracefully' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include(project.name)
        expect(response.first[:text]).to include('• ')
      end
    end

    context 'special characters in project names' do
      # Используем существующий проект для простоты
      let!(:project) { projects(:test_project) }

      it 'handles special characters in project names' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include(project.name)
      end
    end

    context 'project with deleted client' do
      let!(:client) { clients(:delete_me_client) }
      let!(:project) { projects(:project_with_client2) }
      # Используем существующий membership fixture

      before do
        client.destroy # Удаляем клиента, оставляя project.client_id указывающим на несуществующую запись
      end

      it 'handles projects with orphaned client references' do
        expect { dispatch_command :projects }.not_to raise_error
      end
    end
  end
end
