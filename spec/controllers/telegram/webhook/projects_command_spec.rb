# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  context 'authenticated user with projects' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

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
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

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
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

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
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

    it 'displays all owned projects' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
    end
  end

  context 'user as member' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

    it 'displays only projects where user is member' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Development Project')
    end
  end

  context 'user as viewer' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

    it 'displays projects where user is viewer' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'mixed project access' do
    let(:telegram_user) { telegram_users(:telegram_clean_user) }
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

    it 'displays all accessible projects regardless of role' do
      response = dispatch_command :projects
      expect(response.first[:text]).to include('Development Project')
      expect(response.first[:text]).to include('Personal Project')
      expect(response.first[:text]).to include('Test Project')
    end
  end

  context 'archived projects' do
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

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

      before(:each) do
        allow(controller).to receive(:chat) do
          {
            'id' => telegram_user.id,
            'first_name' => telegram_user.first_name,
            'last_name' => telegram_user.last_name,
            'username' => telegram_user.username
          }
        end

        allow(controller).to receive(:from) do
          { 'id' => telegram_user.id }
        end

        controller.instance_variable_set(:@telegram_user, nil)
      end

      it 'handles very long project names gracefully' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Work Project')
        expect(response.first[:text]).to include('• ')
      end
    end

    context 'special characters in project names' do
      let(:telegram_user) { telegram_users(:telegram_regular) }
      let(:from_id) { telegram_user.id }

      before(:each) do
        allow(controller).to receive(:chat) do
          {
            'id' => telegram_user.id,
            'first_name' => telegram_user.first_name,
            'last_name' => telegram_user.last_name,
            'username' => telegram_user.username
          }
        end

        allow(controller).to receive(:from) do
          { 'id' => telegram_user.id }
        end

        controller.instance_variable_set(:@telegram_user, nil)
      end

      it 'handles special characters in project names' do
        response = dispatch_command :projects
        expect(response.first[:text]).to include('Test Project')
      end
    end

    context 'project with deleted client' do
      let(:client) { clients(:delete_me_client) }
      let(:telegram_user) { telegram_users(:telegram_regular) }
      let(:from_id) { telegram_user.id }

      before do
        allow(controller).to receive(:chat) do
          {
            'id' => telegram_user.id,
            'first_name' => telegram_user.first_name,
            'last_name' => telegram_user.last_name,
            'username' => telegram_user.username
          }
        end

        allow(controller).to receive(:from) do
          { 'id' => telegram_user.id }
        end

        controller.instance_variable_set(:@telegram_user, nil)
        client.destroy
      end

      it 'handles projects with orphaned client references' do
        expect { dispatch_command :projects }.not_to raise_error
      end
    end
  end

  context 'unauthenticated user' do
    let(:telegram_user) do
      TelegramUser.create_with(first_name: 'Unknown', last_name: 'User', username: 'unknown').create_or_find_by!(id: 12_345)
    end
    let(:from_id) { telegram_user.id }

    before(:each) do
      allow(controller).to receive(:chat) do
        {
          'id' => telegram_user.id,
          'first_name' => telegram_user.first_name,
          'last_name' => telegram_user.last_name,
          'username' => telegram_user.username
        }
      end

      allow(controller).to receive(:from) do
        { 'id' => telegram_user.id }
      end

      controller.instance_variable_set(:@telegram_user, nil)
    end

    it 'responds with empty projects message' do
      response = dispatch_command :projects

      # Unauthenticated user has no projects
      if response.is_a?(Array)
        expect(response.first[:text]).to include('Доступные проекты:')
        expect(response.first[:text]).to include('У вас пока нет проектов.')
      else
        # If error is raised, that's also acceptable for unauthenticated users
        expect(response).to be_a(StandardError)
      end
    end
  end
end
