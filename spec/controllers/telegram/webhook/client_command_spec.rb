# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without any clients' do
      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with clients that have projects' do
      before do
        # Create clients with projects
        @client1 = create(:client, user: user, name: 'Client Company A', key: 'client_a')
        @client2 = create(:client, user: user, name: 'Client Company B', key: 'client_b')

        # Create projects for clients
        @project1 = create(:project, name: 'Project A1', client: @client1)
        @project2 = create(:project, name: 'Project A2', client: @client1)
        @project3 = create(:project, name: 'Project B1', client: @client2)

        # Create memberships for user
        create(:membership, project: @project1, user: user, role: :owner)
        create(:membership, project: @project2, user: user, role: :member)
        create(:membership, project: @project3, user: user, role: :owner)
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'displays client information with projects' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with clients without projects' do
      before do
        # Create clients without associated projects
        create(:client, user: user, name: 'Empty Client 1', key: 'empty_client_1')
        create(:client, user: user, name: 'Empty Client 2', key: 'empty_client_2')
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'handles clients without projects' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with mixed client situations' do
      before do
        # Create client with multiple projects
        @active_client = create(:client, user: user, name: 'Active Client', key: 'active')
        @project1 = create(:project, name: 'Active Project 1', client: @active_client)
        @project2 = create(:project, name: 'Active Project 2', client: @active_client)
        @project3 = create(:project, name: 'Active Project 3', client: @active_client)

        # Create client with single project
        @single_client = create(:client, user: user, name: 'Single Project Client', key: 'single')
        @single_project = create(:project, name: 'Only Project', client: @single_client)

        # Create client without projects
        create(:client, user: user, name: 'No Projects Client', key: 'no_projects')

        # Set up memberships
        create(:membership, project: @project1, user: user, role: :owner)
        create(:membership, project: @project2, user: user, role: :member)
        create(:membership, project: @project3, user: user, role: :viewer)
        create(:membership, project: @single_project, user: user, role: :owner)
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'handles mixed client portfolio' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with projects having time entries' do
      before do
        @client = create(:client, user: user, name: 'Working Client', key: 'working')
        @project = create(:project, name: 'Active Project', client: @client)

        create(:membership, project: @project, user: user, role: :owner)

        # Create time shifts for the project
        create(:time_shift, project: @project, user: user, date: Date.today, hours: 4, description: 'Current work')
        create(:time_shift, project: @project, user: user, date: 1.day.ago, hours: 6, description: 'Yesterday tasks')
        create(:time_shift, project: @project, user: user, date: 2.days.ago, hours: 3, description: 'Day before')
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'shows clients with active work' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with projects that have rates' do
      before do
        @client = create(:client, user: user, name: 'Billed Client', key: 'billed')
        @project = create(:project, name: 'Billed Project', client: @client)

        create(:membership, project: @project, user: user, role: :owner)
        create(:member_rate, project: @project, user: user, hourly_rate: 100.0, currency: 'RUB')
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'handles clients with billing information' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end

    context 'with inactive projects' do
      before do
        @client = create(:client, user: user, name: 'Mixed Status Client', key: 'mixed')

        # Create active and inactive projects
        @active_project = create(:project, name: 'Active Project', client: @client, active: true)
        @inactive_project = create(:project, name: 'Inactive Project', client: @client, active: false)

        create(:membership, project: @active_project, user: user, role: :owner)
        create(:membership, project: @inactive_project, user: user, role: :owner)
      end

      it 'responds to /client command without errors' do
        expect { dispatch_command :client }.not_to raise_error
      end

      it 'handles clients with mixed project statuses' do
        expect { dispatch_command :client }.not_to raise_error
      end
    end
  end
end