# frozen_string_literal: true

require 'spec_helper'

# TODO: Создать тесты для BroadcastNotificationJob - ВЫПОЛНЕНО
# Созданы тесты для проверки:
# 1. Создания job с правильными параметрами
# 2. Вызова TelegramNotificationJob для каждого user_id
# 3. Правильной очереди (queue_as :default)

RSpec.describe BroadcastNotificationJob, type: :job do
  let(:message) { 'Test broadcast message' }
  let(:telegram_user_ids) { [123_456_789, 987_654_321] }
  let(:job) { BroadcastNotificationJob.new }

  describe 'queue configuration' do
    it 'uses default queue' do
      expect(BroadcastNotificationJob.new.queue_name).to eq('default')
    end
  end

  describe 'job creation' do
    it 'can be created with message and user_ids' do
      expect { BroadcastNotificationJob.new }.not_to raise_error
    end

    it 'can be enqueued with correct parameters' do
      expect do
        BroadcastNotificationJob.perform_later(message, telegram_user_ids)
      end.to have_enqueued_job(BroadcastNotificationJob)
        .with(message, telegram_user_ids)
        .on_queue('default')
    end
  end

  describe '#perform' do
    let(:telegram_user_ids) { [123_456_789, 987_654_321] }

    context 'with multiple telegram user IDs' do
      it 'enqueues TelegramNotificationJob for each user ID' do
        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 123_456_789, message: message)
          .ordered

        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 987_654_321, message: message)
          .ordered

        job.perform(message, telegram_user_ids)
      end
    end

    context 'with single telegram user ID' do
      let(:telegram_user_ids) { [123_456_789] }

      it 'enqueues TelegramNotificationJob once' do
        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 123_456_789, message: message)
          .once

        job.perform(message, telegram_user_ids)
      end
    end

    context 'with empty telegram user IDs array' do
      let(:telegram_user_ids) { [] }

      it 'does not enqueue any TelegramNotificationJob' do
        expect(TelegramNotificationJob).not_to receive(:perform_later)

        job.perform(message, telegram_user_ids)
      end
    end

    context 'with duplicate telegram user IDs' do
      let(:telegram_user_ids) { [123_456_789, 123_456_789, 987_654_321] }

      it 'enqueues TelegramNotificationJob for each ID including duplicates' do
        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 123_456_789, message: message)
          .twice

        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 987_654_321, message: message)
          .once

        job.perform(message, telegram_user_ids)
      end
    end

    context 'with nil message' do
      let(:message) { nil }

      it 'still enqueues jobs with nil message' do
        expect(TelegramNotificationJob).to receive(:perform_later)
          .with(user_id: 123_456_789, message: nil)
          .once

        job.perform(message, [123_456_789])
      end
    end
  end

  describe 'integration with TelegramNotificationJob' do
    let(:telegram_user_ids) { [123_456_789] }

    it 'passes correct arguments to TelegramNotificationJob' do
      expect(TelegramNotificationJob).to receive(:perform_later)
        .with(user_id: 123_456_789, message: message)

      job.perform(message, telegram_user_ids)
    end
  end
end
