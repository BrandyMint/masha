# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TelegramNotificationJob, type: :job do
  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:message) { 'Test notification message' }

  it 'enqueues the job' do
    expect do
      described_class.perform_later(user_id: telegram_user.id, message: message)
    end.to have_enqueued_job(described_class)
  end

  it 'sends a telegram message to the user' do
    allow(Telegram.bot).to receive(:send_message).and_return(true)

    described_class.new.perform(user_id: telegram_user.id, message: message)

    expect(Telegram.bot).to have_received(:send_message).with(
      chat_id: telegram_user.id,
      text: message
    )
  end

  it 'handles missing telegram user gracefully' do
    expect do
      described_class.new.perform(user_id: 999_999_999, message: message)
    end.not_to raise_error
  end

  it 'logs and reports errors from Telegram API' do
    allow(Telegram.bot).to receive(:send_message).and_raise(Telegram::Bot::Forbidden.new('Blocked'))
    allow(Bugsnag).to receive(:notify)
    allow(Rails.logger).to receive(:warn)

    described_class.new.perform(user_id: telegram_user.id, message: message)

    expect(Bugsnag).to have_received(:notify)
    expect(Rails.logger).to have_received(:warn)
  end
end
