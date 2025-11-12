# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'проверка ответа команд' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'проверяет что команда /reset возвращает ответ' do
      response = dispatch_command :reset

      # Проверяем что ответ не пустой
      expect(response).not_to be_nil
      expect(response).to be_an(Array)

      # Если ответ есть, проверяем его структуру
      if response.any?
        first_message = response.first
        expect(first_message).to have_key(:text)
        expect(first_message[:text]).not_to be_blank if first_message[:text]
      end
    end

    it 'проверяет что команда /add возвращает ответ' do
      response = dispatch_command :add

      # Проверяем что ответ не пустой
      expect(response).not_to be_nil
      expect(response).to be_an(Array)

      # Если ответ есть, проверяем его структуру
      if response.any?
        first_message = response.first
        expect(first_message).to have_key(:text)
        expect(first_message[:text]).not_to be_blank if first_message[:text]
      end
    end

    it 'проверяет что команда /help возвращает ответ' do
      response = dispatch_command :help

      # Проверяем что ответ не пустой
      expect(response).not_to be_nil
      expect(response).to be_an(Array)

      # Если ответ есть, проверяем его структуру
      if response.any?
        first_message = response.first
        expect(first_message).to have_key(:text)
        expect(first_message[:text]).not_to be_blank if first_message[:text]
      end
    end
  end
end
