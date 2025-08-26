# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  # for old RSpec:
  # include_context 'telegram/bot/integration/rails'

  # Main method is #dispatch(update). Some helpers are:
  #   dispatch_message(text, options = {})
  #   dispatch_command(cmd, *args)

  # Available matchers can be found in Telegram::Bot::RSpec::ClientMatchers.
  # it 'shows usage of basic matchers' do
  ## The most basic one is #make_telegram_request(bot, endpoint, params_matcher)
  # expect { dispatch_command(:start) }.
  # to make_telegram_request(bot, :sendMessage, hash_including(text: 'msg text'))

  ## There are some shortcuts for dispatching basic updates and testing responses.
  # expect { dispatch_message('Hi') }.to send_telegram_message(bot, /msg regexp/, some: :option)
  # end

  let!(:user) { create :user }

  context 'private chat' do
    let(:chat_id) { from_id }

    context 'unauthenticated user' do
      describe '#start!' do
        subject { -> { dispatch_command :start } }
        it { should respond_with_message(/Привяжи/) }
      end

      describe '#projects!' do
        subject { -> { dispatch_command :projects } }
        it { should respond_with_message(/Привяжи/) }
      end

      describe '#message' do
        subject { -> { dispatch_message 'talk something' } }
        it { should respond_with_message(/конкретика/) }
      end
    end

    context 'logged user' do
      before do
        allow(controller).to receive(:current_user) { user }
      end
      describe '#start!' do
        subject { -> { dispatch_command :start } }
        it { should respond_with_message(/знакомы/) }
      end
    end
  end

  context 'public chat' do
    let(:chat_id) { -from_id }
    describe '#message' do
      subject { -> { dispatch_message 'talk something' } }
      it { should_not respond_with_message }
    end
  end

  ## There is context for callback queries with related matchers,
  ## use :callback_query tag to include it.
  # describe '#hey_callback_query', :callback_query do
  # let(:data) { "hey:#{name}" }
  # let(:name) { 'Joe' }
  # it { should answer_callback_query('Hey Joe') }
  # it { should edit_current_message :text, text: 'Done' }
  # end
end
