# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'with existing projects' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'owner') }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'with multiple projects' do
      let!(:project1) { create(:project, :with_owner) }
      let!(:project2) { create(:project, :with_owner) }
      let!(:membership1) { create(:membership, project: project1, user: user, role: 'owner') }
      let!(:membership2) { create(:membership, project: project2, user: user, role: 'owner') }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as viewer role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as member role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end

      it 'creates project directly with slug parameter' do
        expect {
          dispatch_command :new, 'test-project'
        }.to change(Project, :count).by(1)

        project = Project.last
        expect(project.name).to eq('test-project')
        expect(project.slug).to eq('test-project')
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
        # 1. Create existing project
        existing_project = create(:project, slug: 'existing-project')
        create(:membership, :member, project: existing_project, user: user)

        # 2. Try to create project with same slug
        dispatch_command :new

        expect {
          dispatch_message 'existing-project'
        }.not_to change(Project, :count)

        # 3. Verify original project still exists and unchanged
        expect(Project.find_by(slug: 'existing-project')).to eq(existing_project)
      end
    end
  end
end
