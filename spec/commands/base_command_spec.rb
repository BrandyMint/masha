# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseCommand do
  let(:user) { double('user') }
  let(:telegram_user) { double('telegram_user', developer?: false, user: user) }
  let(:controller) { double('controller', payload: {}, respond_with: true, t: 'translated', telegram_user: telegram_user) }

  describe '.command_metadata' do
    it 'sets developer_only flag' do
      test_class = Class.new(BaseCommand) do
        command_metadata(developer_only: true)
      end

      expect(test_class.developer_only?).to be true
    end

    it 'defaults developer_only to false' do
      test_class = Class.new(BaseCommand)

      expect(test_class.developer_only?).to be false
    end
  end

  describe '#safe_call' do
    context 'when command is developer_only' do
      let(:developer_command_class) do
        Class.new(BaseCommand) do
          command_metadata(developer_only: true)

          def call(*args)
            # Mock implementation
          end
        end
      end

      it 'blocks non-developers' do
        command = developer_command_class.new(controller)

        command.safe_call('arg1', 'arg2')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: I18n.t('telegram.errors.developer_access_denied')
        )
      end

      it 'allows developers' do
        allow(telegram_user).to receive(:developer?).and_return(true)
        command = developer_command_class.new(controller)
        allow(command).to receive(:call)

        command.safe_call('arg1', 'arg2')

        expect(command).to have_received(:call).with('arg1', 'arg2')
      end
    end

    context 'when command is public' do
      let(:public_command_class) do
        Class.new(BaseCommand) do
          def call(*args)
            # Mock implementation
          end
        end
      end

      it 'allows all users' do
        command = public_command_class.new(controller)
        allow(command).to receive(:call)

        command.safe_call('arg1')

        expect(command).to have_received(:call).with('arg1')
      end
    end
  end
end
