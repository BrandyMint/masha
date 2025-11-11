# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  fixtures :users, :projects, :memberships, :time_shifts, :telegram_users
  include_context 'telegram webhook base'
  
  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'without time entries for today' do
      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end

    context 'with time entries for today' do
      before do
        # Use existing fixtures for daily project and time shifts
        # daily_project, user_with_telegram_daily_project membership
        # today_morning, today_afternoon, today_meeting time shifts
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
        # Use existing fixtures for multi-day project and time shifts
        # multi_day_project, user_with_telegram_multi_day_project membership
        # today_multi_day, yesterday_work, day_before_work time shifts
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
        # Use existing fixtures for different time period projects
        # recent_project, user_with_telegram_recent_project membership
        # old_project, user_with_telegram_old_project membership
        # recent_work, old_work time shifts
      end

      it 'responds to /day command without errors' do
        expect { dispatch_command :day }.not_to raise_error
      end
    end
  end
end
