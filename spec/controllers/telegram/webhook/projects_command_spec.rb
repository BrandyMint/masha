# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#projects!' do
    include_context 'private chat'

    context 'unauthenticated user' do
      include_context 'unauthenticated user'

      subject { -> { dispatch_command :projects } }
      it { should respond_with_message(/Привяжи/) }
    end
  end
end
