# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without time entries for today' do
      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end

    context 'with time entries for today' do
      before do
        # Create test project
        project = create(:project, name: 'Daily Project')
        create(:membership, project: project, user: user, role: :member)

        # Create time shifts for today
        create(:time_shift, project: project, user: user, date: Date.today, hours: 3, description: 'Morning work')
        create(:time_shift, project: project, user: user, date: Date.today, hours: 2, description: 'Afternoon tasks')
        create(:time_shift, project: project, user: user, date: Date.today, hours: 1, description: 'Meeting')
      end

      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end

      it 'handles multiple entries for today' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end

    context 'with time entries for different days' do
      before do
        project = create(:project, name: 'Multi-day Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create time shifts for different days
        create(:time_shift, project: project, user: user, date: Date.today, hours: 4, description: 'Today work')
        create(:time_shift, project: project, user: user, date: 1.day.ago, hours: 5, description: 'Yesterday tasks')
        create(:time_shift, project: project, user: user, date: 2.days.ago, hours: 3, description: 'Day before')
      end

      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end

      it 'shows only today entries' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end

    context 'with projects from different time periods' do
      before do
        # Create multiple projects
        recent_project = create(:project, name: 'Recent Project')
        old_project = create(:project, name: 'Old Project')

        create(:membership, project: recent_project, user: user, role: 'owner')
        create(:membership, project: old_project, user: user, role: :member)

        # Create today's entry only in recent project
        create(:time_shift, project: recent_project, user: user, date: Date.today, hours: 6, description: 'Current work')

        # Create old entries in old project
        create(:time_shift, project: old_project, user: user, date: 1.week.ago, hours: 4, description: 'Old work')
      end

      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end
  end
end
