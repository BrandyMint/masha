# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#set_commands!' do
    include_context 'private chat'
    include_context 'authenticated user'

    let(:mock_commands_manager) { double('Telegram::CommandsManager') }

    before do
      allow(Telegram::CommandsManager).to receive(:new).and_return(mock_commands_manager)
      I18n.locale = :ru
    end

    context 'when user is developer' do
      before do
        ENV['DEVELOPER_TELEGRAM_IDS'] = from_id.to_s
      end

      after do
        ENV.delete('DEVELOPER_TELEGRAM_IDS')
      end

      context 'when commands are successfully set' do
        before do
          allow(mock_commands_manager).to receive(:set_commands!).and_return(
            {
              success: true,
              message: 'Команды бота успешно установлены',
              commands_count: 15
            }
          )
        end

        subject { -> { dispatch_command :set_commands } }

        it 'responds with initial setup message' do
          expect(subject).to respond_with_message('🔧 Устанавливаю команды бота...')
        end

        it 'responds with success message and count' do
          expect(subject).to respond_with_message(/Команды бота успешно установлены/)
          expect(subject).to respond_with_message(/📊 Установлено команд: 15/)
        end

        it 'creates commands manager with bot' do
          dispatch_command :set_commands
          expect(Telegram::CommandsManager).to have_received(:new).with(bot: bot)
        end

        it 'calls set_commands! on manager' do
          dispatch_command :set_commands
          expect(mock_commands_manager).to have_received(:set_commands!)
        end
      end

      context 'when commands setup fails' do
        before do
          allow(mock_commands_manager).to receive(:set_commands!).and_return(
            {
              success: false,
              message: 'Ошибка при установке команд: API error'
            }
          )
        end

        subject { -> { dispatch_command :set_commands } }

        it 'responds with error message' do
          expect(subject).to respond_with_message('🔧 Устанавливаю команды бота...')
          expect(subject).to respond_with_message(/Ошибка при установке команд: API error/)
        end
      end

      context 'when exception occurs' do
        before do
          allow(mock_commands_manager).to receive(:set_commands!).and_raise(StandardError, 'Unexpected error')
          allow(Bugsnag).to receive(:notify)
          allow(Rails.logger).to receive(:error)
        end

        subject { -> { dispatch_command :set_commands } }

        it 'notifies Bugsnag' do
          dispatch_command :set_commands
          expect(Bugsnag).to have_received(:notify)
        end

        it 'logs error' do
          dispatch_command :set_commands
          expect(Rails.logger).to have_received(:error).with(/Set commands error/)
        end

        it 'responds with generic error message' do
          expect(subject).to respond_with_message('🔧 Устанавливаю команды бота...')
          expect(subject).to respond_with_message(I18n.t('telegram_bot.error'))
        end
      end
    end

    context 'when user is not developer' do
      before do
        ENV['DEVELOPER_TELEGRAM_IDS'] = '99999'
      end

      after do
        ENV.delete('DEVELOPER_TELEGRAM_IDS')
      end

      subject { -> { dispatch_command :set_commands } }

      it 'responds with access denied message' do
        expect(subject).to respond_with_message(I18n.t('telegram_bot.access_denied'))
      end

      it 'does not create commands manager' do
        dispatch_command :set_commands
        expect(Telegram::CommandsManager).not_to have_received(:new)
      end
    end

    context 'when user is not authenticated' do
      include_context 'private chat'
      include_context 'unauthenticated user'

      before do
        ENV['DEVELOPER_TELEGRAM_IDS'] = from_id.to_s
      end

      after do
        ENV.delete('DEVELOPER_TELEGRAM_IDS')
      end

      subject { -> { dispatch_command :set_commands } }

      it 'does not execute set_commands (handled by before_action)' do
        # The command should be blocked by require_authenticated before_action
        # and should respond with authentication message
        expect(subject).to respond_with_message(/Привязи телеграм/)
      end
    end
  end
end
