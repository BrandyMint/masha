# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'as project owner' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'owner') }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project viewer' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'as project member' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'without projects' do
      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'with multiple projects as owner' do
      let!(:project1) { create(:project, name: 'Project 1') }
      let!(:project2) { create(:project, name: 'Project 2') }
      let!(:membership1) { create(:membership, :owner, project: project1, user: user) }
      let!(:membership2) { create(:membership, :owner, project: project2, user: user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :adduser
        expect(response).not_to be_nil
      end
    end

    context 'with existing members' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:other_user) { create(:user, name: 'Other User') }
      let!(:other_membership) { create(:membership, project: project, user: other_user) }

      it 'responds to /adduser command without errors' do
        expect { dispatch_command :adduser }.not_to raise_error
      end
    end
  end
end
