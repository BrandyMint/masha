# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'with existing projects' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'without projects' do
      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'with multiple projects' do
      let!(:project1) { projects(:work_project) }
      let!(:project2) { projects(:test_project) }
      let!(:membership1) { memberships(:telegram_work) }
      let!(:membership2) { memberships(:telegram_test) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'as viewer role' do
      let!(:project) { projects(:inactive_project) }
      let!(:membership) { memberships(:telegram_inactive) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'as member role' do
      let!(:project) { projects(:test_project) }
      let!(:membership) { memberships(:telegram_test) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'with existing time shifts' do
      let!(:project) { projects(:work_project) }
      let!(:membership) { memberships(:telegram_work) }
      let!(:time_shift) { time_shifts(:telegram_time_today) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end
    end
  end
end
