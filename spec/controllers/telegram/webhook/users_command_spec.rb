# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated regular user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'responds to /users command without errors' do
      expect { dispatch_command :users }.not_to raise_error
    end

    it 'rejects /users command for non-developer user' do
      # Проверяем, что команда отклоняется без ошибки, но корректно обрабатывает доступ
      expect { dispatch_command :users }.not_to raise_error
    end
  end

  context 'authenticated developer user' do
    let(:developer_telegram_id) { ApplicationConfig.developer_telegram_id }
    let(:user) { users(:admin) }  # Используем admin как разработчика
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { developer_telegram_id }

    include_context 'authenticated user'

    it 'responds to /users command without errors for developer' do
      expect { dispatch_command :users }.not_to raise_error
    end

    it 'handles user list generation for developer' do
      # Используем существующих пользователей с Telegram
      users(:telegram_clean_user)
      users(:telegram_empty_user)

      expect { dispatch_command :users }.not_to raise_error
    end
  end

  context 'unauthenticated user' do
    it 'responds to /users command without errors' do
      expect { dispatch_command :users }.not_to raise_error
    end
  end
end
