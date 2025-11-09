# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without any time entries' do
      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries in current week' do
      before do
        project = create(:project, name: 'Current Week Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create time shifts for current week
        create(:time_shift, project: project, user: user, date: Date.today, hours: 4, description: 'Monday work')
        create(:time_shift, project: project, user: user, date: Date.today - 1.day, hours: 6, description: 'Sunday work')
        create(:time_shift, project: project, user: user, date: Date.today - 2.days, hours: 5, description: 'Saturday tasks')
        create(:time_shift, project: project, user: user, date: Date.today - 3.days, hours: 8, description: 'Friday development')
        create(:time_shift, project: project, user: user, date: Date.today - 4.days, hours: 3, description: 'Thursday meeting')
        create(:time_shift, project: project, user: user, date: Date.today - 5.days, hours: 7, description: 'Wednesday coding')
        create(:time_shift, project: project, user: user, date: Date.today - 6.days, hours: 2, description: 'Tuesday planning')
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end

      it 'handles weekly hours calculation' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries spanning multiple weeks' do
      before do
        project = create(:project, name: 'Multi-week Project')
        create(:membership, project: project, user: user, role: :member)

        # Create time shifts across multiple weeks
        # Current week
        create(:time_shift, project: project, user: user, date: Date.today, hours: 5, description: 'Current week task 1')
        create(:time_shift, project: project, user: user, date: Date.today - 1.day, hours: 3, description: 'Current week task 2')

        # Previous week
        create(:time_shift, project: project, user: user, date: Date.today - 7.days, hours: 8, description: 'Last week task 1')
        create(:time_shift, project: project, user: user, date: Date.today - 8.days, hours: 6, description: 'Last week task 2')
        create(:time_shift, project: project, user: user, date: Date.today - 9.days, hours: 4, description: 'Last week task 3')

        # Two weeks ago
        create(:time_shift, project: project, user: user, date: Date.today - 14.days, hours: 7, description: 'Two weeks ago work')
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries from different projects' do
      before do
        # Create multiple projects
        project1 = create(:project, name: 'Project Alpha')
        project2 = create(:project, name: 'Project Beta')
        project3 = create(:project, name: 'Project Gamma')

        # Create memberships
        create(:membership, project: project1, user: user, role: :owner)
        create(:membership, project: project2, user: user, role: :member)
        create(:membership, project: project3, user: user, role: :member)

        # Create time shifts across different projects for current week
        create(:time_shift, project: project1, user: user, date: Date.today, hours: 4, description: 'Alpha work')
        create(:time_shift, project: project2, user: user, date: Date.today - 1.day, hours: 3, description: 'Beta development')
        create(:time_shift, project: project3, user: user, date: Date.today - 2.days, hours: 5, description: 'Gamma testing')
        create(:time_shift, project: project1, user: user, date: Date.today - 3.days, hours: 6, description: 'Alpha review')
        create(:time_shift, project: project2, user: user, date: Date.today - 4.days, hours: 2, description: 'Beta meeting')
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end

      it 'handles hours from multiple projects' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with single day high hour entries' do
      before do
        project = create(:project, name: 'Intensive Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create multiple entries for the same day
        create(:time_shift, project: project, user: user, date: Date.today, hours: 4, description: 'Morning session')
        create(:time_shift, project: project, user: user, date: Date.today, hours: 3, description: 'Afternoon coding')
        create(:time_shift, project: project, user: user, date: Date.today, hours: 2, description: 'Evening review')
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries from previous month only' do
      before do
        project = create(:project, name: 'Last Month Project')
        create(:membership, project: project, user: user, role: :member)

        # Create time shifts from last month
        create(:time_shift, project: project, user: user, date: 1.month.ago, hours: 5, description: 'Last month work')
        create(:time_shift, project: project, user: user, date: 1.month.ago - 1.day, hours: 7, description: 'Last month task 2')
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end
  end
end