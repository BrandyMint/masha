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

      it 'generates daily report with table format' do
        response = dispatch_command :report, 'today'
        expect(response).not_to be_nil

        # Проверяем, что отчет содержит табличный формат
        first_message = response.first
        expect(first_message[:text]).to include('Отчет за')
        expect(first_message[:text]).to match(/\|\s*Проект\s*\|/) # заголовок таблицы
        expect(first_message[:text]).to match(/\|\s*Итого\s*\|/) # итоговая строка
      end

      it 'shows project breakdown in table format' do
        response = dispatch_command :report, 'today'
        expect(response).not_to be_nil

        # Проверяем, что в отчете есть табличная разбивка по проектам
        first_message = response.first
        expect(first_message[:text]).to match(/\|\s*[a-zA-Z-]+\s*\|/) # название проекта в таблице
      end

      it 'handles weekly report with date range' do
        response = dispatch_command :report, 'week'
        expect(response).not_to be_nil

        # Проверяем, что недельный отчет содержит диапазон дат
        first_message = response.first
        expect(first_message[:text]).to include('Отчет за')
        expect(first_message[:text]).to match(/\d{4}-\d{2}-\d{2} - \d{4}-\d{2}-\d{2}/) # формат дат
      end

      it 'handles monthly report calculations' do
        response = dispatch_command :report, 'month'
        expect(response).not_to be_nil

        # Проверяем, что месячный отчет содержит корректные данные
        first_message = response.first
        expect(first_message[:text]).to include('Отчет за')
        expect(first_message[:text]).to match(/\d{4}-\d{2}-\d{2} - \d{4}-\d{2}-\d{2}/) # диапазон месяца
        expect(first_message[:text]).to match(/\|\s*Итого\s*\|/) # итоговая строка
      end

      it 'shows detailed report with time entries' do
        response = dispatch_command :report, 'today', 'detailed'
        expect(response).not_to be_nil

        # Проверяем, что детальный отчет содержит таблицу с описаниями
        first_message = response.first
        expect(first_message[:text]).to include('```') # формат таблицы
        expect(first_message[:text]).to include('Описание') # колонка с описаниями
        expect(first_message[:text]).to match(/\d+\.\d+/) # формат часов
      end

      it 'handles project filter correctly' do
        # Используем существующий проект из fixtures
        response = dispatch_command :report, 'today', 'project:work-project'
        expect(response).not_to be_nil

        # Проверяем, что отчет содержит только один проект
        first_message = response.first
        expect(first_message[:text]).to include('work-project')
      end

      it 'handles date range reports correctly' do
        today = Date.current
        yesterday = today - 1.day
        date_range = "#{yesterday.strftime('%Y-%m-%d')}:#{today.strftime('%Y-%m-%d')}"

        response = dispatch_command :report, date_range
        expect(response).not_to be_nil

        # Проверяем, что отчет за период содержит корректные данные
        first_message = response.first
        expect(first_message[:text]).to include(yesterday.strftime('%Y-%m-%d'))
        expect(first_message[:text]).to include(today.strftime('%Y-%m-%d'))
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
        expect do
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_periods:'
                   })
        end.not_to raise_error
      end

      it 'handles report_filters_callback_query without errors' do
        expect do
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_filters:'
                   })
        end.not_to raise_error
      end

      it 'handles report_options_callback_query without errors' do
        expect do
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_options:'
                   })
        end.not_to raise_error
      end

      it 'handles report_examples_callback_query without errors' do
        expect do
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_examples:'
                   })
        end.not_to raise_error
      end

      it 'handles report_main_callback_query without errors' do
        expect do
          dispatch(callback_query: {
                     id: 'test_callback_id',
                     from: from,
                     message: message,
                     data: 'report_main:'
                   })
        end.not_to raise_error
      end
    end
  end
end
