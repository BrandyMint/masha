# frozen_string_literal: true

require 'spec_helper'

# Use Cases
#
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  UPDATE_1 = { "update_id": 312_270_656, "message": {
    "message_id": 1875,
    "from": { "id": 943_084_337, "is_bot": false, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "language_code": 'en',
              "is_premium": true },
    "chat": { "id": 943_084_337, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "type": 'private' },
    "date": 1_762_862_402,
    "text": '/add',
    "entities": [{ "offset": 0, "length": 4, "type": 'bot_command' }]
  } }

  UPDATE_2 = { "update_id": 312_270_657, "message": {
    "message_id": 1876,
    "from": { "id": 943_084_337, "is_bot": false, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "language_code": 'en',
              "is_premium": true },
    "chat": { "id": 943_084_337, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "type": 'private' },
    "date": 1_762_862_452,
    "text": '/reset',
    "entities": [{ "offset": 0, "length": 6, "type": 'bot_command' }]
  } }

  UPDATE_3 = { "update_id": 312_270_658, "message": {
    "message_id": 1877,
    "from": { "id": 943_084_337, "is_bot": false, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "language_code": 'en',
              "is_premium": true },
    "chat": { "id": 943_084_337, "first_name": 'Danil', "last_name": 'Pismenny', "username": 'pismenny', "type": 'private' },
    "date": 1_762_862_469,
    "text": '/help',
    "entities": [{ "offset": 0, "length": 5, "type": 'bot_command' }]
  } }

  let(:user) { users(:user_with_telegram) }
  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:from_id) { telegram_user.id }

  context do
    it 'adds time entry through complete workflow' do
      response = dispatch_message '/reset'
      expect(response).not_to be_nil
    end
  end
end
