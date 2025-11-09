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
      let!(:project1) { create(:project, name: 'Project 1') }
      let!(:project2) { create(:project, name: 'Project 2') }
      let!(:membership1) { create(:membership, :owner, project: project1, user: user) }
      let!(:membership2) { create(:membership, :owner, project: project2, user: user) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'as viewer role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :viewer, project: project, user: user) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'as member role' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, project: project, user: user) }

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end

      it 'does not return nil response' do
        response = dispatch_command :attach
        expect(response).not_to be_nil
      end
    end

    context 'with existing time shifts' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:time_shift) do
        create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'Test work')
      end

      it 'responds to /attach command without errors' do
        expect { dispatch_command :attach }.not_to raise_error
      end
    end
  end
end
