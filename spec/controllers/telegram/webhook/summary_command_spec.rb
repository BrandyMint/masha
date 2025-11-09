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
      it 'responds to /summary command without errors' do
        expect { dispatch_command :summary }.not_to raise_error
      end
    end

    context 'with time entries in multiple projects' do
      before do
        # Create multiple projects
        web_project = create(:project, name: 'Web Development')
        mobile_project = create(:project, name: 'Mobile App')
        design_project = create(:project, name: 'Design Work')

        # Create memberships
        create(:membership, project: web_project, user: user, role: :owner)
        create(:membership, project: mobile_project, user: user, role: :member)
        create(:membership, project: design_project, user: user, role: :member)

        # Create time shifts across different projects
        create(:time_shift, project: web_project, user: user, date: Date.today, hours: 4, description: 'Frontend development')
        create(:time_shift, project: web_project, user: user, date: 1.day.ago, hours: 3, description: 'Backend API')
        create(:time_shift, project: mobile_project, user: user, date: 2.days.ago, hours: 5, description: 'Mobile UI')
        create(:time_shift, project: mobile_project, user: user, date: 3.days.ago, hours: 2, description: 'Bug fixes')
        create(:time_shift, project: design_project, user: user, date: 4.days.ago, hours: 6, description: 'Mockups')
        create(:time_shift, project: design_project, user: user, date: 5.days.ago, hours: 4, description: 'Wireframes')
      end

      it 'responds to /summary command without errors' do
        expect { dispatch_command :summary }.not_to raise_error
      end

      it 'handles summary across multiple projects' do
        expect { dispatch_command :summary }.not_to raise_error
      end
    end

    context 'with time entries spanning different months' do
      before do
        project = create(:project, name: 'Long-term Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create time shifts across different time periods
        create(:time_shift, project: project, user: user, date: Date.today, hours: 3, description: 'Current work')
        create(:time_shift, project: project, user: user, date: 1.week.ago, hours: 5, description: 'Last week')
        create(:time_shift, project: project, user: user, date: 1.month.ago, hours: 8, description: 'Last month')
        create(:time_shift, project: project, user: user, date: 2.months.ago, hours: 6, description: 'Two months ago')
      end

      it 'responds to /summary command without errors' do
        expect { dispatch_command :summary }.not_to raise_error
      end
    end

    context 'with single project time entries' do
      before do
        project = create(:project, name: 'Single Project')
        create(:membership, project: project, user: user, role: :owner)

        # Create multiple entries in one project
        create(:time_shift, project: project, user: user, date: Date.today, hours: 2, description: 'Task 1')
        create(:time_shift, project: project, user: user, date: Date.today, hours: 3, description: 'Task 2')
        create(:time_shift, project: project, user: user, date: 1.day.ago, hours: 4, description: 'Task 3')
      end

      it 'responds to /summary command without errors' do
        expect { dispatch_command :summary }.not_to raise_error
      end
    end

    context 'with high hour entries' do
      before do
        project = create(:project, name: 'Heavy Load Project')
        create(:membership, project: project, user: user, role: :member)

        # Create entries with significant hours
        create(:time_shift, project: project, user: user, date: Date.today, hours: 8, description: 'Full day work')
        create(:time_shift, project: project, user: user, date: 1.day.ago, hours: 10, description: 'Overtime')
        create(:time_shift, project: project, user: user, date: 2.days.ago, hours: 6, description: 'Regular day')
      end

      it 'responds to /summary command without errors' do
        expect { dispatch_command :summary }.not_to raise_error
      end
    end
  end
end
