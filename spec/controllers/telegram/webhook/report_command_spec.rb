# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without time entries' do
      it 'responds to /report command without errors' do
        expect { dispatch_command :report }.not_to raise_error
      end
    end

    context 'with time entries' do
      before do
        # Create test projects
        project1 = create(:project, name: 'Web Development')
        project2 = create(:project, name: 'Mobile App')

        # Create memberships for the user
        create(:membership, project: project1, user: user, role: :owner)
        create(:membership, project: project2, user: user, role: :member)

        # Create time shifts for current month
        create(:time_shift, project: project1, user: user, date: 3.days.ago, hours: 4, description: 'Frontend development')
        create(:time_shift, project: project1, user: user, date: 2.days.ago, hours: 3, description: 'Backend API')
        create(:time_shift, project: project2, user: user, date: 1.day.ago, hours: 5, description: 'Mobile UI')
        create(:time_shift, project: project2, user: user, date: Date.today, hours: 2, description: 'Bug fixes')
      end

      it 'responds to /report command without errors' do
        expect { dispatch_command :report }.not_to raise_error
      end

      it 'handles /report with current month data' do
        expect { dispatch_command :report }.not_to raise_error
      end
    end

    context 'with old time entries' do
      before do
        project = create(:project, name: 'Old Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create time shifts from previous month
        create(:time_shift, project: project, user: user, date: 1.month.ago, hours: 6, description: 'Legacy work')
        create(:time_shift, project: project, user: user, date: 2.months.ago, hours: 4, description: 'Maintenance')
      end

      it 'responds to /report command without errors' do
        expect { dispatch_command :report }.not_to raise_error
      end
    end
  end
end
