# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  # Helper to set up controller mocks for Telegram user
  def setup_telegram_user_mocks(telegram_user)
    allow(controller).to receive(:chat).and_return({
                                                     'id' => telegram_user.id,
                                                     'first_name' => telegram_user.first_name,
                                                     'last_name' => telegram_user.last_name,
                                                     'username' => telegram_user.username
                                                   })

    allow(controller).to receive(:from).and_return({
                                                     'id' => telegram_user.id
                                                   })
  end

  context 'developer user' do
    let!(:telegram_user) do
      TelegramUser.create_with(first_name: 'Developer', last_name: 'User', username: 'dev')
                  .create_or_find_by(id: ApplicationConfig.developer_telegram_id)
    end
    let(:from_id) { ApplicationConfig.developer_telegram_id }

    before do
      setup_telegram_user_mocks(telegram_user)
    end

    it 'responds to /notify command without errors' do
      expect { dispatch_command :notify }.not_to raise_error
    end

    context 'complete notify workflow' do
      let!(:test_telegram_users) { [telegram_users(:telegram_regular), telegram_users(:telegram_admin)] }

      it 'requests message input when /notify is called' do
        response = dispatch_command :notify

        expect(response).not_to be_nil
        # Check that response contains request for message input
        expect(response.first[:text]).to include(I18n.t('commands.notify.prompts.enter_message'))
      end

      it 'broadcasts notification when valid message is provided' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send notification message and check job was enqueued
        expect do
          dispatch_message('Система будет обновлена в 18:00')
        end.to have_enqueued_job(BroadcastNotificationJob).with(
          'Система будет обновлена в 18:00',
          kind_of(Array)
        )
      end

      it 'cancels operation when cancel is sent' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send cancel message
        expect do
          dispatch_message('cancel')
        end.not_to have_enqueued_job(BroadcastNotificationJob)
      end

      it 'rejects empty message' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send empty message and check error response
        response = dispatch_message('')
        expect(response.last[:text]).to include(I18n.t('commands.notify.errors.empty_message'))
      end

      it 'rejects too short message' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send short message and check error response
        response = dispatch_message('х')
        expect(response.last[:text]).to include(I18n.t('commands.notify.errors.too_short'))
      end

      it 'rejects too long message' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send long message and check error response
        long_message = 'a' * 4001
        response = dispatch_message(long_message)
        expect(response.last[:text]).to include(I18n.t('commands.notify.errors.too_long'))
      end

      it 'accepts message with minimum valid length' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send message with exactly 3 characters
        expect do
          dispatch_message('123')
        end.to have_enqueued_job(BroadcastNotificationJob)
      end

      it 'accepts message with maximum valid length' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send message with exactly 4000 characters
        max_message = 'a' * 4000
        expect do
          dispatch_message(max_message)
        end.to have_enqueued_job(BroadcastNotificationJob)
      end

      it 'handles cancel with different case variations' do
        # 1. Call /notify command
        dispatch_command :notify

        # 2. Send cancel in different cases
        %w[CANCEL Cancel cAnCel].each do |cancel_variant|
          expect do
            dispatch_message(cancel_variant)
          end.not_to have_enqueued_job(BroadcastNotificationJob)
        end
      end
    end
  end

  context 'regular user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'denies access for non-developer user' do
      response = dispatch_command :notify
      expect(response).not_to be_nil
      expect(response.first[:text]).to include(I18n.t('commands.notify.errors.access_denied'))
    end

    it 'does not allow any interaction for non-developer user' do
      # Call /notify command
      dispatch_command :notify

      # Try to send message after access denied
      expect do
        dispatch_message('Some message')
      end.not_to have_enqueued_job(BroadcastNotificationJob)
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 123_456_789 }
    let(:telegram_user) { nil }

    it 'denies access for unauthenticated user' do
      response = dispatch_command :notify
      expect(response).not_to be_nil
      expect(response.first[:text]).to include(I18n.t('commands.notify.errors.access_denied'))
    end
  end
end
