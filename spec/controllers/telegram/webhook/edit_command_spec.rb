# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'with existing time shift' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:time_shift) do
        create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'Test work')
      end

      it 'responds to /edit command without errors' do
        expect { dispatch_command :edit }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :edit
        expect(response).not_to be_nil
      end
    end

    context 'without time shifts' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'responds to /edit command without errors' do
        expect { dispatch_command :edit }.not_to raise_error
      end
    end

    context 'without projects' do
      it 'responds to /edit command without errors' do
        expect { dispatch_command :edit }.not_to raise_error
      end
    end
  end
end