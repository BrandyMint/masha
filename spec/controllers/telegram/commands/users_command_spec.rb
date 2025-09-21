# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::UsersCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:developer?).and_return(developer)
    allow(controller).to receive(:format_user_info).and_return('user info')
    stub_const('ApplicationConfig', double(developer_telegram_id: 123))
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
      let!(:users) { create_list(:user, 2) }

      it 'responds with users information' do
        command.call

        expect(controller).to have_received(:format_user_info).at_least(:once)
        expect(controller).to have_received(:respond_with)
          .with(:message, text: kind_of(String), parse_mode: :Markdown)
      end
    end
  end
end
