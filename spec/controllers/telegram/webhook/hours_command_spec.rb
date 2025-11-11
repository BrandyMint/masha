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

    context 'without any time entries' do
      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries in current week' do
      before do
        # Use fixtures instead of create()
        # project: current_week_project, membership: user_with_telegram_current_week_project

        # Time shifts for current week are already defined in fixtures
        # hours_current_monday, hours_current_sunday, hours_current_saturday,
        # hours_current_friday, hours_current_thursday, hours_current_wednesday,
        # hours_current_tuesday
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
        # Use fixtures instead of create()
        # project: multi_week_project, membership: user_with_telegram_multi_week_project

        # Time shifts across multiple weeks are already defined in fixtures
        # hours_multi_current_1, hours_multi_current_2,
        # hours_multi_last_1, hours_multi_last_2, hours_multi_last_3,
        # hours_multi_two_weeks
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries from different projects' do
      before do
        # Use fixtures instead of create()
        # Projects: project_alpha, project_beta, project_gamma
        # Memberships: user_with_telegram_project_alpha, user_with_telegram_project_beta, user_with_telegram_project_gamma

        # Time shifts across different projects for current week are already defined in fixtures
        # hours_alpha_today, hours_beta_yesterday, hours_gamma_2_days,
        # hours_alpha_3_days, hours_beta_4_days
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
        # Use fixtures instead of create()
        # project: intensive_project, membership: user_with_telegram_intensive_project

        # Multiple entries for the same day are already defined in fixtures
        # hours_intensive_morning, hours_intensive_afternoon, hours_intensive_evening
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end

    context 'with time entries from previous month only' do
      before do
        # Use fixtures instead of create()
        # project: last_month_project, membership: user_with_telegram_last_month_project

        # Time shifts from last month are already defined in fixtures
        # hours_last_month_1, hours_last_month_2
      end

      it 'responds to /hours command without errors' do
        expect { dispatch_command :hours }.not_to raise_error
      end
    end
  end
end
