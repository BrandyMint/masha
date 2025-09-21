# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::StartCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:telegram_user) { double(id: 123) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:logged_in?).and_return(logged_in)
    allow(controller).to receive(:multiline).and_return('welcome message')
    allow(controller).to receive(:help_message).and_return('help text')
    allow(controller).to receive(:telegram_user).and_return(telegram_user)
  end

  describe '#call' do
    context 'when word starts with auth prefix' do
      let(:logged_in) { false }
      let(:word) { 'auth_session_token' }
      let(:verifier) { double('verifier') }

      before do
        allow(Rails.application).to receive(:message_verifier).with(:telegram).and_return(verifier)
        allow(verifier).to receive(:generate).and_return('generated_token')
        allow(Rails.application.routes.url_helpers).to receive(:telegram_confirm_url)
          .with(token: 'generated_token').and_return('confirm_url')
      end

      it 'handles auth start' do
        command.call(word)

        expected_data = { st: 'session_token', tid: 123, t: kind_of(Integer) }
        expect(verifier).to have_received(:generate).with(expected_data, purpose: :login)
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
