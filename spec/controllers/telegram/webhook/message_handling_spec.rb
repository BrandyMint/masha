# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#message' do
    context 'public chat' do
      include_context 'public chat'

      subject { -> { dispatch_message 'talk something' } }
      it { should_not respond_with_message }
    end
  end
end
