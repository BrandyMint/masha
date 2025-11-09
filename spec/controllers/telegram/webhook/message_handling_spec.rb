# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  # Define the missing methods for tests
  before do
    allow(controller).to receive(:chat).and_return({ 'id' => from_id })
  end

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    before do
      @project = create(:project, :with_owner, name: 'Work Project', slug: 'work')
      create(:membership, project: @project, user: user, role: :member)
    end

    context 'message processing' do
      it 'processes valid time tracking message without errors' do
        expect { controller.message('2.5 work testing feature') }.not_to raise_error
      end

      it 'processes reverse format message without errors' do
        expect { controller.message('work 1.5 bug fixing') }.not_to raise_error
      end

      it 'processes message without description without errors' do
        expect { controller.message('3 work') }.not_to raise_error
      end

      it 'processes decimal comma without errors' do
        expect { controller.message('1,5 work some work') }.not_to raise_error
      end

      it 'processes unicode characters without errors' do
        expect { controller.message('2.5 work разработка функции') }.not_to raise_error
      end
    end

    context 'message validation' do
      it 'handles blank message without errors' do
        expect { controller.message('') }.not_to raise_error
      end

      it 'handles message with too few parts without errors' do
        expect { controller.message('2.5') }.not_to raise_error
      end

      it 'handles whitespace-only message without errors' do
        expect { controller.message('   ') }.not_to raise_error
      end
    end

    context 'error handling' do
      it 'handles non-existent project without errors' do
        expect { controller.message('2.5 nonexistent test') }.not_to raise_error
      end

      it 'handles invalid time format without errors' do
        expect { controller.message('abc work test') }.not_to raise_error
      end

      it 'handles too much time without errors' do
        expect { controller.message('25 work test') }.not_to raise_error
      end

      it 'handles too little time without errors' do
        expect { controller.message('0.05 work test') }.not_to raise_error
      end

      it 'handles negative time without errors' do
        expect { controller.message('-2 work test') }.not_to raise_error
      end
    end

    context 'TelegramTimeTracker integration' do
      it 'integrates with TelegramTimeTracker service' do
        expect(TelegramTimeTracker).to receive(:new).with(user, anything, anything).and_call_original

        expect { controller.message('2.5 work testing') }.not_to raise_error
      end

      it 'handles TelegramTimeTracker parsing' do
        # Mock the service to verify integration
        tracker = double('TelegramTimeTracker')
        expect(TelegramTimeTracker).to receive(:new).and_return(tracker)
        expect(tracker).to receive(:parse_and_add).and_return({ success: true })

        expect { controller.message('2.5 work testing') }.not_to raise_error
      end
    end
  end
end
