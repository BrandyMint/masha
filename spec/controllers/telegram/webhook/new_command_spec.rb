# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'with existing projects' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user, role: 'owner') }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :new
        expect(response).not_to be_nil
      end
    end

    context 'without projects' do
      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :new
        expect(response).not_to be_nil
      end
    end

    context 'with multiple projects' do
      let!(:project1) { create(:project, :with_owner) }
      let!(:project2) { create(:project, :with_owner) }
      let!(:membership1) { create(:membership, project: project1, user: user, role: 'owner') }
      let!(:membership2) { create(:membership, project: project2, user: user, role: 'owner') }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as viewer role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end

    context 'as member role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user) }

      it 'responds to /new command without errors' do
        expect { dispatch_command :new }.not_to raise_error
      end
    end
  end
end
