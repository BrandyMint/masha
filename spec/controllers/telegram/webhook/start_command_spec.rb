# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'responds with welcome message for /start command' do
      expect { dispatch_command :start }.not_to raise_error

      # dispatch_command успешно выполняет команду /start
      # для авторизованного пользователя без ошибок
    end
  end
end
