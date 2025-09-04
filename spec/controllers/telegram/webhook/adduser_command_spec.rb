# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#adduser!' do
    include_context 'private chat'
    include_context 'authenticated user'

    context 'without parameters' do
      subject { -> { dispatch_command :adduser } }
      it { should respond_with_message(/Укажите название проекта/) }
    end

    context 'without username' do
      subject { -> { dispatch_command :adduser, 'project1' } }
      it { should respond_with_message(/Укажите никнейм пользователя/) }
    end
  end
end