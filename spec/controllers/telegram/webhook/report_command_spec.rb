# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
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
        # Use existing fixtures for projects, memberships and time shifts
        # Projects: web_development, mobile_app
        # Memberships: user_with_telegram_web_dev_owner, user_with_telegram_mobile_app_member
        # TimeShifts: report_web_dev_3_days_ago, report_web_dev_2_days_ago,
        #             report_mobile_app_1_day_ago, report_mobile_app_today
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
        # Use existing fixtures for old project and time shifts
        # Project: old_report_project
        # Membership: user_with_telegram_old_project_owner
        # TimeShifts: report_old_last_month, report_old_two_months_ago
      end

      it 'responds to /report command without errors' do
        expect { dispatch_command :report }.not_to raise_error
      end
    end

    context 'callback query handlers', :callback_query do
      let(:message) { { message_id: 1, chat: chat } }
      let(:data) { 'report_periods:' }

      it 'handles report_periods_callback_query without errors' do
        expect {
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_periods:'
                   })
        }.not_to raise_error
      end

      it 'handles report_filters_callback_query without errors' do
        expect {
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_filters:'
                   })
        }.not_to raise_error
      end

      it 'handles report_options_callback_query without errors' do
        expect {
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_options:'
                   })
        }.not_to raise_error
      end

      it 'handles report_examples_callback_query without errors' do
        expect {
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_examples:'
                   })
        }.not_to raise_error
      end

      it 'handles report_main_callback_query without errors' do
        expect {
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_main:'
                   })
        }.not_to raise_error
      end
    end
  end
end
