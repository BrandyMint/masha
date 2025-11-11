# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'with existing projects' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'with multiple projects' do
      let!(:project1) { projects(:work_project) }
      let!(:project2) { projects(:test_project) }
      let!(:membership1) { memberships(:telegram_work) }
      let!(:membership2) { memberships(:telegram_test) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as viewer role' do
      let!(:project) { projects(:inactive_project) }
      let!(:membership) { memberships(:clean_user_viewer_project) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as member role' do
      let!(:project) { projects(:test_project) }
      let!(:membership) { memberships(:telegram_test) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end

      it 'creates project directly with slug parameter' do
        expect {
          dispatch_command :new, 'new-test-project'
        }.to change(Project, :count).by(1)

        project = Project.last
        expect(project.name).to eq('new-test-project')
        expect(project.slug).to eq('new-test-project')
        expect(project.users).to include(user)
        expect(user.memberships.where(project: project, role_cd: 0)).to exist
      end

      it 'creates project through multi-step workflow' do
        # 1. User calls /new without parameters
        dispatch_command :new

        # 3. User provides project slug
        expect {
          dispatch_message 'my-awesome-project'
        }.to change(Project, :count).by(1)

        # 4. Verify project was created with correct attributes
        project = Project.last
        expect(project.name).to eq('my-awesome-project')
        expect(project.slug).to eq('my-awesome-project')
        expect(project.users).to include(user)

        # 5. Verify user is owner of the project
        membership = user.memberships.find_by(project: project)
        expect(membership.role_cd).to eq(0) # owner role = 0
      end

      it 'rejects empty project slug' do
        # 1. Start project creation workflow
        dispatch_command :new

        # 2. Send empty slug - should not create project
        expect {
          dispatch_message ''
        }.not_to change(Project, :count)

        # 3. Verify no project was created
        expect(Project.where(name: '')).not_to exist
      end

      it 'rejects invalid slug format' do
        # 1. Start project creation workflow
        dispatch_command :new

        # 2. Send invalid slug with forbidden characters
        expect {
          dispatch_message 'project@name'
        }.not_to change(Project, :count)

        # 3. Verify no project was created
        expect(Project.where(slug: 'project@name')).not_to exist
      end

      it 'handles duplicate project slug gracefully' do
        # 1. Use existing project from fixtures
        existing_project = projects(:work_project)
        membership = memberships(:telegram_work)

        # 2. Try to create project with same slug
        dispatch_command :new

        expect {
          dispatch_message existing_project.slug
        }.not_to change(Project, :count)

        # 3. Verify original project still exists and unchanged
        expect(Project.find_by(slug: existing_project.slug)).to eq(existing_project)
      end
    end
  end
end
