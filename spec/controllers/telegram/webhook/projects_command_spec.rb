# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    # Create test projects for the user
    before do
      create(:project, :with_owner, name: 'Test Project 1')
      create(:project, :with_owner, name: 'Test Project 2')
    end

    it 'responds to /projects command without errors' do
      expect { dispatch_command :projects }.not_to raise_error
    end
  end
end