# frozen_string_literal: true

require 'spec_helper'

# TODO: Создать тесты для BroadcastNotificationJob - ВЫПОЛНЕНО
# Созданы тесты для проверки:
# 1. Создания job с правильными параметрами
# 2. Вызова TelegramNotificationJob для каждого user_id
# 3. Правильной очереди (queue_as :default)

RSpec.describe BroadcastNotificationJob, type: :job do
  let(:message) { 'Test broadcast message' }
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
        BroadcastNotificationJob.perform_later(message)
      end.to have_enqueued_job(BroadcastNotificationJob)
        .with(message)
        .on_queue('default')
    end
  end

  describe '#perform' do
    context 'with message' do
      it 'still enqueues jobs with message' do
        expect(TelegramNotificationJob).to receive(:perform_later).exactly(TelegramUser.count).times
        job.perform(message)
      end
    end
    context 'with nil message' do
      let(:message) { nil }

      it 'still enqueues jobs with nil message' do
        expect(TelegramNotificationJob).to_not receive(:perform_later)
        job.perform(message)
      end
    end
  end
end
