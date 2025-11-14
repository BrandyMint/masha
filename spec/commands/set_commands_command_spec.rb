# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCommandsCommand do
  let(:controller) { double('controller', developer?: false, respond_with: true) }
  let(:command) { described_class.new(controller) }

  describe 'metadata' do
    it 'is marked as developer_only' do
      expect(described_class.developer_only?).to be true
    end
  end

  describe '#call' do
    context 'when user is developer' do
      let(:controller) { double('controller', developer?: true, respond_with: true) }

      before do
        allow(Telegram.bots[:default]).to receive(:set_my_commands)
      end

      it 'sets commands via Telegram API' do
        command.safe_call

        expect(Telegram.bots[:default]).to have_received(:set_my_commands).with(
          commands: array_including(
            hash_including(command: 'add', description: String),
            hash_including(command: 'start', description: String)
          )
        )
      end

      it 'responds with success message' do
        command.safe_call

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: match(/✅ Команды установлены успешно!/)
        )
      end

      it 'excludes developer_only commands from menu' do
        command.safe_call

        expect(Telegram.bots[:default]).to have_received(:set_my_commands) do |args|
          command_names = args[:commands].map { |c| c[:command] }
          expect(command_names).not_to include('notify', 'merge', 'set_commands')
        end
      end
    end

    context 'when user is not developer' do
      it 'blocks access' do
        command.safe_call

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: I18n.t('telegram.errors.developer_access_denied')
        )
      end

      it 'does not call Telegram API' do
        allow(Telegram.bots[:default]).to receive(:set_my_commands)

        command.safe_call

        expect(Telegram.bots[:default]).not_to have_received(:set_my_commands)
      end
    end

    context 'when API call fails' do
      let(:controller) { double('controller', developer?: true, respond_with: true) }

      before do
        allow(Telegram.bots[:default]).to receive(:set_my_commands).and_raise(StandardError, 'API error')
      end

      it 'responds with error message' do
        command.safe_call

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: match(/❌ Ошибка установки команд: API error/)
        )
      end
    end
  end
end
