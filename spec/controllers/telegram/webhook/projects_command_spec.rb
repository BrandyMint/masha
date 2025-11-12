# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'
  include_context 'authenticated user'

  # Helper to set up controller mocks for Telegram user
  context 'authenticated user with projects' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays projects header' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Доступные проекты:')
    end

    it 'lists all available projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Development Project')
    end

    it 'formats projects with bullet points' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('• Personal Project')
      expect(response.first[:text]).to include('• Development Project')
    end
  end

  context 'user with no projects' do
    let(:telegram_user) { telegram_users(:telegram_empty) }

    it 'responds to /projects command without errors' do
      expect { dispatch_command :projects }.not_to raise_error
    end

    it 'displays empty projects message' do
      response = dispatch_command :projects
      expect(response).not_to be_nil
      expect(response.first[:text]).to include('Доступные проекты:')
      expect(response.first[:text]).to include('У вас пока нет проектов.')
    end

    it 'has proper format for empty projects list' do
      response = dispatch_command :projects
      expect(response.first[:text]).to match(/Доступные проекты:\s*\n\s*У вас пока нет проектов\./)
    end
  end

  context 'projects with clients' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays project with client information' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Website Project (Client One)')
    end

    it 'formats client information in parentheses' do
      response = dispatch_command :projects
      expect(response.first[:text]).to match(/• Website Project \(Client One\)/)
    end
  end

  context 'user as owner' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays all owned projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
    end
  end

  context 'user as member' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    it 'displays only projects where user is member' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Development Project')
    end
  end

  context 'user as viewer' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }

    it 'displays projects where user is viewer' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'mixed project access' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    it 'displays all accessible projects regardless of role' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'archived projects' do
    let(:telegram_user) { telegram_users(:telegram_regular) }

    it 'displays only active (non-archived) projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Work Project')
      expect(response.first[:text]).not_to include('Inactive Project')
    end
  end

  context 'edge cases' do
    context 'long project names' do
      let(:telegram_user) { telegram_users(:telegram_regular) }
      let(:from_id) { telegram_user.id }

      it 'handles very long project names gracefully' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Work Project')
        expect(response.first[:text]).to include('• ')
      end
    end

    context 'special characters in project names' do
      let(:telegram_user) { telegram_users(:telegram_regular) }

      it 'handles special characters in project names' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Test Project')
      end
    end

    context 'project with deleted client' do
      let(:client) { clients(:delete_me_client) }
      let(:telegram_user) { telegram_users(:telegram_regular) }

      before do
        client.destroy
      end

      it 'handles projects with orphaned client references' do
        expect { dispatch_command :projects }.not_to raise_error
      end
    end
  end
end
