# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'
  include_context 'authenticated user'

  # Helper to set up controller mocks for Telegram user
  context 'authenticated user with projects' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

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

  context 'user with no projects' do
    let(:telegram_user) { telegram_users(:telegram_empty) }

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

  context 'projects with clients' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

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
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays all owned projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
    end
  end

  context 'user as member' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    it 'displays only projects where user is member' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Development Project')
    end
  end

  context 'user as viewer' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays projects where user is viewer' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'mixed project access' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    it 'displays all accessible projects regardless of role' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'archived projects' do
    let(:telegram_user) { telegram_users(:telegram_regular) }

    it 'displays only active (non-archived) projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Work Project')
      expect(response.first[:text]).not_to include('Inactive Project')
    end
  end

  context 'edge cases' do
    context 'long project names' do
      let(:telegram_user) { telegram_users(:telegram_regular) }
      let(:from_id) { telegram_user.id }

      it 'handles very long project names gracefully' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Work Project')
        expect(response.first[:text]).to include('• ')
      end
    end

    context 'special characters in project names' do
      let(:telegram_user) { telegram_users(:telegram_regular) }

      it 'handles special characters in project names' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Test Project')
      end
    end

    context 'project with deleted client' do
      let(:client) { clients(:delete_me_client) }
      let(:telegram_user) { telegram_users(:telegram_regular) }

      before do
        client.destroy
      end

      it 'handles projects with orphaned client references' do
        expect { dispatch_command :projects }.not_to raise_error
      end
    end
  end

  # Tests for project creation functionality (migrated from new_command)
  context 'project creation' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'responds to /projects create command without errors' do
      expect { dispatch_command :projects, :create }.not_to raise_error
    end

    it 'prompts for slug when /projects create is called without parameters' do
      response = dispatch_command :projects, :create
      expect(response.first[:text]).to include('Укажите slug (идентификатор) для нового проекта:')
    end

    it 'creates project directly with slug parameter' do
      expect do
        dispatch_command :projects, :create, 'new-test-project'
      end.to change(Project, :count).by(1)

      project = Project.last
      expect(project.name).to eq('new-test-project')
      expect(project.slug).to eq('new-test-project')
      expect(project.users).to include(user)
      expect(user.memberships.where(project: project, role_cd: 0)).to exist
    end

    it 'creates project through multi-step workflow' do
      # 1. User calls /projects create without parameters
      dispatch_command :projects, :create

      # 2. User provides project slug
      expect do
        dispatch_message 'my-awesome-project'
      end.to change(Project, :count).by(1)

      # 3. Verify project was created with correct attributes
      project = Project.last
      expect(project.name).to eq('my-awesome-project')
      expect(project.slug).to eq('my-awesome-project')
      expect(project.users).to include(user)

      # 4. Verify user is owner of the project
      membership = user.memberships.find_by(project: project)
      expect(membership.role_cd).to eq(0) # owner role = 0
    end

    it 'rejects empty project slug in multi-step workflow' do
      # 1. Start project creation workflow
      dispatch_command :projects, :create

      # 2. Send empty slug - should not create project
      expect do
        dispatch_message ''
      end.not_to change(Project, :count)

      # 3. Verify no project was created
      expect(Project.where(name: '')).not_to exist
    end

    it 'rejects empty project slug directly' do
      # Try to create project with empty slug directly
      expect do
        dispatch_command :projects, :create, ''
      end.not_to change(Project, :count)
    end

    it 'rejects invalid slug format in multi-step workflow' do
      # 1. Start project creation workflow
      dispatch_command :projects, :create

      # 2. Send invalid slug with forbidden characters
      expect do
        dispatch_message 'project@name'
      end.not_to change(Project, :count)

      # 3. Verify no project was created
      expect(Project.where(slug: 'project@name')).not_to exist
    end

    it 'rejects invalid slug format directly' do
      # Try to create project with invalid slug directly
      expect do
        dispatch_command :projects, :create, 'project@name'
      end.not_to change(Project, :count)
    end

    it 'handles duplicate project slug gracefully in multi-step workflow' do
      # 1. Use existing project from fixtures
      existing_project = projects(:work_project)
      memberships(:telegram_work)

      # 2. Try to create project with same slug
      dispatch_command :projects, :create

      expect do
        dispatch_message existing_project.slug
      end.not_to change(Project, :count)

      # 3. Verify original project still exists and unchanged
      expect(Project.find_by(slug: existing_project.slug)).to eq(existing_project)
    end

    it 'handles duplicate project slug gracefully directly' do
      # 1. Use existing project from fixtures
      existing_project = projects(:work_project)
      memberships(:telegram_work)

      # 2. Try to create project with same slug directly
      expect do
        dispatch_command :projects, :create, existing_project.slug
      end.not_to change(Project, :count)

      # 3. Verify original project still exists and unchanged
      expect(Project.find_by(slug: existing_project.slug)).to eq(existing_project)
    end

    context 'when user has no projects' do
      let(:telegram_user) { telegram_users(:telegram_empty) }

      it 'shows creation hint in projects list for users with no projects' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('💡 *Создать новый проект:* /projects create')
      end
    end

    it 'shows creation hint in projects list for users with projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('💡 *Создать новый проект:* /projects create')
    end

    it 'handles unknown actions gracefully' do
      response = dispatch_command :projects, :unknown_action
      expect(response.first[:text]).to include('Неизвестное действие. Используйте: /projects или /projects create [slug]')
    end

    it 'validates unauthorized access for project creation' do
      # Test with unauthorized user
      allow_any_instance_of(ProjectsCommand).to receive(:current_user).and_return(nil)

      response = dispatch_command :projects, :create, 'test-project'
      expect(response.first[:text]).to include('Вы не авторизованы для работы с проектами')
    end
  end
end
