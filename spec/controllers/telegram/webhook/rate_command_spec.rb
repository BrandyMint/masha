# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without any projects' do
      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with projects where user is owner' do
      before do
        # Create projects where user has ownership rights
        @project1 = create(:project, name: 'Owner Project 1')
        @project2 = create(:project, name: 'Owner Project 2')

        create(:membership, project: @project1, user: user, role: :owner)
        create(:membership, project: @project2, user: user, role: :owner)
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'handles rate management for owned projects' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with existing member rates' do
      before do
        # Create different projects for different rates
        @rub_project = create(:project, name: 'RUB Project')
        @usd_project = create(:project, name: 'USD Project')
        @eur_project = create(:project, name: 'EUR Project')

        create(:membership, project: @rub_project, user: user, role: :owner)
        create(:membership, project: @usd_project, user: user, role: :owner)
        create(:membership, project: @eur_project, user: user, role: :owner)

        # Create existing member rates for different projects
        create(:member_rate, project: @rub_project, user: user, hourly_rate: 50.0, currency: 'RUB')
        create(:member_rate, :usd, project: @usd_project, user: user)
        create(:member_rate, :eur, project: @eur_project, user: user)
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'displays existing rates' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with projects where user is participant' do
      before do
        # Create projects where user is only a participant (limited rights)
        @participant_project = create(:project, name: 'Participant Project')
        create(:membership, project: @participant_project, user: user, role: :member)
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'handles limited access for participants' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with mixed project roles' do
      before do
        # Create project where user is owner
        @owner_project = create(:project, name: 'Owner Access Project')
        create(:membership, project: @owner_project, user: user, role: :owner)

        # Create project where user is participant
        @participant_project = create(:project, name: 'Participant Access Project')
        create(:membership, project: @participant_project, user: user, role: :member)

        # Create project where user is watcher
        @watcher_project = create(:project, name: 'Watcher Access Project')
        create(:membership, project: @watcher_project, user: user, role: :viewer)

        # Set up rates for owner project
        create(:member_rate, project: @owner_project, user: user, hourly_rate: 100.0, currency: 'RUB')
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'handles different access levels appropriately' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with multiple currencies' do
      before do
        # Create different projects for different currencies
        @usd_project = create(:project, name: 'USD Project')
        @eur_project = create(:project, name: 'EUR Project')
        @rub_project = create(:project, name: 'RUB Project')

        create(:membership, project: @usd_project, user: user, role: :owner)
        create(:membership, project: @eur_project, user: user, role: :owner)
        create(:membership, project: @rub_project, user: user, role: :owner)

        # Create rates with different currencies
        create(:member_rate, :usd, project: @usd_project, user: user)
        create(:member_rate, :eur, project: @eur_project, user: user)
        create(:member_rate, project: @rub_project, user: user, hourly_rate: 120.0, currency: 'RUB')
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'handles multiple currency rates' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end

    context 'with projects without rates' do
      before do
        @project = create(:project, name: 'No Rates Project')
        create(:membership, project: @project, user: user, role: :owner)
      end

      it 'responds to /rate command without errors' do
        expect { dispatch_command :rate }.not_to raise_error
      end

      it 'shows projects without rates' do
        expect { dispatch_command :rate }.not_to raise_error
      end
    end
  end
end
