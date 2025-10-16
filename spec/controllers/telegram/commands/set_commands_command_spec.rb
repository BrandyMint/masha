# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::SetCommandsCommand, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  let(:command) { described_class.new(controller) }
  let(:mock_commands_manager) { double('Telegram::CommandsManager') }

  before do
    allow(Telegram::CommandsManager).to receive(:new).and_return(mock_commands_manager)
    I18n.locale = :ru
  end

  describe '#call' do
    include_context 'private chat'
    include_context 'authenticated user'

    context 'when user is developer' do
      before do
        allow(command).to receive(:developer_user?).and_return(true)
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

        it 'responds with initial setup message' do
          expect { command.call }.to respond_with_message('🔧 Устанавливаю команды бота...')
        end

        it 'responds with success message and count' do
          expect { command.call }.to respond_with_message(/Команды бота успешно установлены/)
          expect { command.call }.to respond_with_message(/📊 Установлено команд: 15/)
        end

        it 'creates commands manager with bot' do
          command.call
          expect(Telegram::CommandsManager).to have_received(:new).with(bot: bot)
        end

        it 'calls set_commands! on manager' do
          command.call
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

        it 'responds with error message' do
          expect { command.call }.to respond_with_message('🔧 Устанавливаю команды бота...')
          expect { command.call }.to respond_with_message(/Ошибка при установке команд: API error/)
        end
      end

      context 'when exception occurs' do
        before do
          allow(mock_commands_manager).to receive(:set_commands!).and_raise(StandardError, 'Unexpected error')
          allow(Bugsnag).to receive(:notify)
          allow(Rails.logger).to receive(:error)
        end

        it 'notifies Bugsnag' do
          command.call
          expect(Bugsnag).to have_received(:notify)
        end

        it 'logs error' do
          command.call
          expect(Rails.logger).to have_received(:error).with(/Set commands error/)
        end

        it 'responds with generic error message' do
          expect { command.call }.to respond_with_message('🔧 Устанавливаю команды бота...')
          expect { command.call }.to respond_with_message(I18n.t('telegram_bot.error'))
        end
      end
    end

    context 'when user is not developer' do
      before do
        allow(command).to receive(:developer_user?).and_return(false)
      end

      it 'responds with access denied message' do
        expect { command.call }.to respond_with_message(I18n.t('telegram_bot.access_denied'))
      end

      it 'does not create commands manager' do
        command.call
        expect(Telegram::CommandsManager).not_to have_received(:new)
      end
    end
  end

  describe '#developer_user?' do
    include_context 'private chat'
    include_context 'authenticated user'

    context 'when DEVELOPER_TELEGRAM_IDS is set' do
      before do
        ENV['DEVELOPER_TELEGRAM_IDS'] = '12345,67890'
      end

      after do
        ENV.delete('DEVELOPER_TELEGRAM_IDS')
      end

      context 'when user telegram_id is in developer list' do
        before do
          user.telegram_user.update!(telegram_id: 12_345)
        end

        it 'returns true' do
          expect(command.send(:developer_user?)).to be true
        end
      end

      context 'when user telegram_id is not in developer list' do
        before do
          user.telegram_user.update!(telegram_id: 99_999)
        end

        it 'returns false' do
          expect(command.send(:developer_user?)).to be false
        end
      end

      context 'when user has no telegram_user' do
        before do
          user.update!(telegram_user: nil)
        end

        it 'returns false' do
          expect(command.send(:developer_user?)).to be false
        end
      end
    end

    context 'when DEVELOPER_TELEGRAM_IDS is not set' do
      before do
        ENV.delete('DEVELOPER_TELEGRAM_IDS')
      end

      it 'returns false' do
        expect(command.send(:developer_user?)).to be false
      end
    end

    context 'when user is not logged in' do
      before do
        allow(command).to receive(:current_user).and_return(nil)
      end

      it 'returns false' do
        expect(command.send(:developer_user?)).to be false
      end
    end
  end
end
