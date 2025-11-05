# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::SummaryCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:code).and_return('```code```')
  end

  describe '#call' do
    context 'when no period provided' do
      it 'shows help text' do
        command.call

        expect(controller).to have_received(:respond_with) do |type, options|
          expect(type).to eq(:message)
          expect(options[:parse_mode]).to eq(:Markdown)
          expect(options[:text]).to include('📊 *Команда /summary')
          expect(options[:text]).to include('Форматы использования:')
          expect(options[:text]).to include('Формат даты: ГГГГ-ММ-ДД')
        end
      end
    end

    context 'when period is provided' do
      before do
        allow(PeriodParser).to receive(:parse).and_return('parsed_period')
      end

      it 'parses period and generates summary' do
        reporter = instance_double(Reporter)
        allow(Reporter).to receive(:new).and_return(reporter)
        allow(reporter).to receive(:projects_to_users_matrix).with(user, 'parsed_period').and_return('summary text')

        command.call('week')

        expect(PeriodParser).to have_received(:parse).with('week')
        expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
      end
    end

    context 'error handling' do
      it 'handles ArgumentError with user-friendly message' do
        allow(PeriodParser).to receive(:parse).and_raise(ArgumentError, 'Invalid format')

        command.call('invalid')

        expect(controller).to have_received(:respond_with).with(:message, text: '❌ Invalid format')
      end

      it 'handles StandardError with generic message' do
        allow(PeriodParser).to receive(:parse).and_raise(StandardError, 'Unexpected error')
        allow(Rails.logger).to receive(:error)

        command.call('test')

        expect(Rails.logger).to have_received(:error).with('SummaryCommand error: Unexpected error')
        expect(controller).to have_received(:respond_with).with(:message, text: '❌ Произошла ошибка. Попробуйте еще раз.')
      end
    end

    context 'relative periods' do
      %w[day week month last_month last_week last_day].each do |period|
        it "handles #{period} period" do
          allow(PeriodParser).to receive(:parse).with(period).and_return(period)
          reporter = instance_double(Reporter)
          allow(Reporter).to receive(:new).and_return(reporter)
          allow(reporter).to receive(:projects_to_users_matrix).with(user, period).and_return('summary text')

          command.call(period)

          expect(PeriodParser).to have_received(:parse).with(period)
          expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
        end
      end
    end

    context 'date formats' do
      it 'handles specific date' do
        allow(PeriodParser).to receive(:parse).with('2024-11-05').and_return(date_hash: 'value')
        reporter = instance_double(Reporter)
        allow(Reporter).to receive(:new).and_return(reporter)
        allow(reporter).to receive(:projects_to_users_matrix).with(user, date_hash: 'value').and_return('summary text')

        command.call('2024-11-05')

        expect(PeriodParser).to have_received(:parse).with('2024-11-05')
        expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
      end

      it 'handles month format' do
        allow(PeriodParser).to receive(:parse).with('2024-11').and_return(month_hash: 'value')
        reporter = instance_double(Reporter)
        allow(Reporter).to receive(:new).and_return(reporter)
        allow(reporter).to receive(:projects_to_users_matrix).with(user, month_hash: 'value').and_return('summary text')

        command.call('2024-11')

        expect(PeriodParser).to have_received(:parse).with('2024-11')
        expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
      end

      it 'handles date range' do
        allow(PeriodParser).to receive(:parse).with('2024-11-01..2024-11-05').and_return(range_hash: 'value')
        reporter = instance_double(Reporter)
        allow(Reporter).to receive(:new).and_return(reporter)
        allow(reporter).to receive(:projects_to_users_matrix).with(user, range_hash: 'value').and_return('summary text')

        command.call('2024-11-01..2024-11-05')

        expect(PeriodParser).to have_received(:parse).with('2024-11-01..2024-11-05')
        expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
      end
    end
  end
end
