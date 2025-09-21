# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::StartCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:logged_in?).and_return(logged_in)
    allow(controller).to receive(:multiline).and_return('welcome message')
    allow(controller).to receive(:help_message).and_return('help text')
    allow(controller).to receive(:telegram_user).and_return(double(id: 123))
  end

  describe '#call' do
    context 'when word starts with auth prefix' do
      let(:logged_in) { false }
      let(:word) { "#{TelegramHelper::AUTH_PREFIX}session_token" }

      before do
        stub_const('TelegramHelper::AUTH_PREFIX', 'auth_')
        allow(Rails.application).to receive_message_chain(:message_verifier, :generate)
          .and_return('token')
        allow(Rails.application.routes.url_helpers).to receive(:telegram_confirm_url)
          .and_return('confirm_url')
      end

      it 'handles auth start' do
        command.call(word)

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Вы авторизованы! Перейдите на сайт: confirm_url')
      end
    end

    context 'when user is logged in' do
      let(:logged_in) { true }

      it 'responds with welcome back message' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'welcome message')
      end
    end

    context 'when user is not logged in' do
      let(:logged_in) { false }

      before do
        allow(Rails.application.routes.url_helpers).to receive(:new_session_url)
          .and_return('login_url')
      end

      it 'responds with login instruction' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Привет! Чтобы авторизоваться перейдите на сайт: login_url')
      end
    end
  end
end
