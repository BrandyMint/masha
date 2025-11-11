# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'as project owner' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /rename command without errors' do
        expect { dispatch_command :rename }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :rename
        expect(response).not_to be_nil
      end
    end

    context 'as project viewer' do
      let!(:project) { projects(:inactive_project) }
      let!(:membership) { memberships(:telegram_inactive) }

      it 'responds to /rename command without errors' do
        expect { dispatch_command :rename }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :rename
        expect(response).not_to be_nil
      end
    end

    context 'as project member' do
      let!(:project) { projects(:test_project) }
      let!(:membership) { memberships(:telegram_test) }

      it 'responds to /rename command without errors' do
        expect { dispatch_command :rename }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :rename
        expect(response).not_to be_nil
      end
    end

    context 'without projects' do
      it 'responds to /rename command without errors' do
        expect { dispatch_command :rename }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :rename
        expect(response).not_to be_nil
      end
    end

    context 'with multiple projects as owner' do
      let!(:project1) { projects(:project_with_client1) }
      let!(:project2) { projects(:project_with_client2) }
      let!(:membership1) { memberships(:telegram_with_client) }
      let!(:membership2) { memberships(:telegram_orphan) }

      it 'responds to /rename command without errors' do
        expect { dispatch_command :rename }.not_to raise_error
      end
    end
  end
end
