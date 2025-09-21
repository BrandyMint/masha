# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::UsersCommand, type: :controller do
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
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Эта команда доступна только разработчику системы')
      end
    end

    context 'when user is developer' do
      let(:developer) { true }
      let(:users) { [create(:user)] }

      before do
        allow(User).to receive_message_chain(:includes, :map, :join).and_return('users info')
        allow(controller).to receive(:format_user_info).and_return('user info')
      end

      it 'responds with users information' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'users info', parse_mode: :Markdown)
      end
    end
  end
end
