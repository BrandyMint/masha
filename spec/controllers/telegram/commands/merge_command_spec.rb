# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::MergeCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:developer?).and_return(developer)
  end

  describe '#call' do
    context 'when user is not developer' do
      let(:developer) { false }

      it 'responds with access denied message' do
        command.call('email@test.com', 'username')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Эта команда доступна только разработчику системы')
      end
    end

    context 'when user is developer' do
      let(:developer) { true }

      context 'with missing arguments' do
        it 'responds with usage message when email is blank' do
          command.call(nil, 'username')

          expect(controller).to have_received(:respond_with)
            .with(:message, text: 'Использование: /merge email@example.com telegram_username')
        end

        it 'responds with usage message when username is blank' do
          command.call('email@test.com', nil)

          expect(controller).to have_received(:respond_with)
            .with(:message, text: 'Использование: /merge email@example.com telegram_username')
        end
      end

      context 'with valid arguments' do
        let(:merger) { instance_double(TelegramUserMerger) }

        before do
          allow(TelegramUserMerger).to receive(:new).and_return(merger)
          allow(merger).to receive(:merge)
        end

        it 'creates merger and calls merge' do
          command.call('email@test.com', 'username')

          expect(TelegramUserMerger).to have_received(:new)
            .with('email@test.com', 'username', controller: controller)
          expect(merger).to have_received(:merge)
        end
      end
    end
  end
end
