# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    # Create test project for adding time entries
    before do
      @project = create(:project, :with_owner, name: 'Work Project')
      create(:membership, project: @project, user: user, role: :member)
    end

    it 'responds to /add command without errors' do
      expect { dispatch_command :add }.not_to raise_error
    end
  end
end