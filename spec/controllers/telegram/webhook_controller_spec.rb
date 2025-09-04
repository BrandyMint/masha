# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  # Main webhook controller specs have been split into separate files:
  # - spec/controllers/telegram/webhook/start_command_spec.rb
  # - spec/controllers/telegram/webhook/projects_command_spec.rb
  # - spec/controllers/telegram/webhook/adduser_command_spec.rb
  # - spec/controllers/telegram/webhook/add_command_spec.rb
  # - spec/controllers/telegram/webhook/message_handling_spec.rb
  #
  # Shared contexts are available in spec/support/shared_contexts/telegram_webhook_shared.rb

  ## There is context for callback queries with related matchers,
  ## use :callback_query tag to include it.
  # describe '#hey_callback_query', :callback_query do
  # let(:data) { "hey:#{name}" }
  # let(:name) { 'Joe' }
  # it { should answer_callback_query('Hey Joe') }
  # it { should edit_current_message :text, text: 'Done' }
  # end
end
