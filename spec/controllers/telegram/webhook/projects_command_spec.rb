# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'user with no projects' do
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
      let!(:project1) { create(:project, name: 'Work Project') }
      let!(:project2) { create(:project, name: 'Personal Project') }
      let!(:membership1) { create(:membership, :member, project: project1, user: user) }
      let!(:membership2) { create(:membership, :member, project: project2, user: user) }

      it 'displays projects header' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Доступные проекты:')
      end

      it 'lists all available projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Work Project')
        expect(response.first[:text]).to include('Personal Project')
      end

      it 'formats projects with bullet points' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('• Work Project')
        expect(response.first[:text]).to include('• Personal Project')
      end
    end

    context 'projects with clients' do
      let!(:client) { create(:client, name: 'Acme Corp') }
      let!(:project) { create(:project, name: 'Website Project', client: client) }
      let!(:membership) { create(:membership, :member, project: project, user: user) }

      it 'displays project with client information' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Website Project (Acme Corp)')
      end

      it 'formats client information in parentheses' do
        response = dispatch_command :projects

        expect(response.first[:text]).to match(/• Website Project \(Acme Corp\)/)
      end
    end

    context 'user as owner' do
      let!(:project1) { create(:project, name: 'Owner Project 1') }
      let!(:project2) { create(:project, name: 'Owner Project 2') }
      let!(:membership1) { create(:membership, :owner, project: project1, user: user) }
      let!(:membership2) { create(:membership, :owner, project: project2, user: user) }

      it 'displays all owned projects' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Owner Project 1')
        expect(response.first[:text]).to include('Owner Project 2')
      end
    end

    context 'user as member' do
      let!(:member_project) { create(:project, name: 'Member Project') }
      let!(:owner_project) { create(:project, name: 'Other Owner Project') }
      let!(:member_membership) { create(:membership, :member, project: member_project, user: user) }
      let!(:owner_membership) { create(:membership, :owner, project: owner_project, user: create(:user)) }

      it 'displays only projects where user is member' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Member Project')
        expect(response.first[:text]).not_to include('Other Owner Project')
      end
    end

    context 'user as viewer' do
      let!(:viewer_project) { create(:project, name: 'Viewer Project') }
      let!(:viewer_membership) { create(:membership, :viewer, project: viewer_project, user: user) }

      it 'displays projects where user is viewer' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('Viewer Project')
      end
    end

    context 'mixed project access' do
      let!(:owned_project) { create(:project, name: 'My Project') }
      let!(:member_project) { create(:project, name: 'Team Project') }
      let!(:viewer_project) { create(:project, name: 'Monitor Project') }
      let!(:client) { create(:client, name: 'Client Co') }

      before do
        create(:membership, :owner, project: owned_project, user: user)
        create(:membership, :member, project: member_project, user: user)
        create(:membership, :viewer, project: viewer_project, user: user)

        # Добавляем клиент к одному из проектов
        member_project.update!(client: client)
      end

      it 'displays all accessible projects regardless of role' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include('My Project')
        expect(response.first[:text]).to include('Team Project (Client Co)')
        expect(response.first[:text]).to include('Monitor Project')
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds with empty projects message' do
      response = dispatch_command :projects

      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Доступные проекты:')
      expect(response.first[:text]).to include('У вас пока нет проектов.')
    end
  end

  context 'archived projects' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    let!(:active_project) { create(:project, name: 'Active Project') }
    let!(:archived_project) { create(:project, name: 'Archived Project', active: false) }
    let!(:active_membership) { create(:membership, :member, project: active_project, user: user) }
    let!(:archived_membership) { create(:membership, :member, project: archived_project, user: user) }

    it 'displays only active (non-archived) projects' do
      response = dispatch_command :projects

      expect(response.first[:text]).to include('Active Project')
      expect(response.first[:text]).not_to include('Archived Project')
    end
  end

  context 'edge cases' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'long project names' do
      let(:long_name) { 'A' * 100 + ' Very Long Project Name That Might Break Formatting' }
      let!(:project) { create(:project, name: long_name) }
      let!(:membership) { create(:membership, :member, project: project, user: user) }

      it 'handles very long project names gracefully' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include(long_name)
        expect(response.first[:text]).to include('• ')
      end
    end

    context 'special characters in project names' do
      let(:special_name) { 'Project @#$%^&*()_+-={}[]|\\:";\'<>?,./ 项目' }
      let!(:project) { create(:project, name: special_name) }
      let!(:membership) { create(:membership, :member, project: project, user: user) }

      it 'handles special characters in project names' do
        response = dispatch_command :projects

        expect(response.first[:text]).to include(special_name)
      end
    end

    context 'project with deleted client' do
      let!(:client) { create(:client, name: 'To Be Deleted') }
      let!(:project) { create(:project, name: 'Orphan Project', client: client) }
      let!(:membership) { create(:membership, :member, project: project, user: user) }

      before do
        client.destroy  # Удаляем клиента, оставляя project.client_id указывающим на несуществующую запись
      end

      it 'handles projects with orphaned client references' do
        expect { dispatch_command :projects }.not_to raise_error
      end
    end
  end
end
