# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::OwnerCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  
  describe '#call' do
    before do
      allow(controller).to receive(:respond_with)
      allow(controller).to receive(:developer?).and_return(developer)
      # Mock the code method to return formatted text
      allow(controller).to receive(:code) do |text|
        "```\n#{text}\n```"
      end
    end
    context 'when user is not developer' do
      let(:developer) { false }

      it 'responds with access denied message' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Эта команда доступна только разработчику системы')
      end
    end

    context 'when user is developer' do
      let(:developer) { true }

      context 'with no arguments' do
        let!(:project1) { create(:project, name: 'Project 1', slug: 'project-1') }
        let!(:project2) { create(:project, name: 'Project 2', slug: 'project-2', active: false) }
        let!(:project3) { create(:project, name: 'Orphaned Project', slug: 'orphaned-project') }
        let!(:owner) { create(:user) }
        let!(:telegram_user) { create(:telegram_user, user: owner, username: 'owner') }

        before do
          project1.memberships.create!(user: owner, role_cd: 0) # owner
          # project2 and project3 have no owners (orphaned)
        end

        it 'shows all projects with owners in table format' do
          command.call

          expect(controller).to have_received(:respond_with) do |type, options|
            expect(type).to eq(:message)
            expect(options[:parse_mode]).to eq(:Markdown)
            expect(options[:text]).to include('Project 1')
            expect(options[:text]).to include('project-1')
            expect(options[:text]).to include('Project 2')
            expect(options[:text]).to include('Orphaned Project')
          end
        end

        it 'shows orphaned projects correctly' do
          command.call

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Нет владельца')
          end
        end
      end

      context 'with filter arguments' do
        let!(:active_project) { create(:project, active: true) }
        let!(:archived_project) { create(:project, active: false) }

        it 'filters active projects' do
          command.call('active')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Активных проекты')
          end
        end

        it 'filters archived projects' do
          command.call('archived')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Архивных проекты')
          end
        end

        it 'shows orphaned projects' do
          command.call('orphaned')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Проекты без владельца')
          end
        end

        it 'searches projects' do
          command.call('search test')

          expect(controller).to have_received(:respond_with)
        end

        it 'shows search usage when search without term' do
          command.call('search')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Использование: /owner search {текст_поиска}')
          end
        end

        it 'handles unknown filters' do
          command.call('unknown')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Неизвестный фильтр')
          end
        end
      end

      context 'with two arguments (changing owner)' do
        let!(:project) { create(:project, slug: 'test-project') }
        let!(:old_owner) { create(:user, email: 'old@example.com') }
        let!(:new_owner) { create(:user, email: 'new@example.com') }
        let!(:old_owner_telegram) { create(:telegram_user, user: old_owner, username: 'oldowner') }

        before do
          project.memberships.create!(user: old_owner, role: 'owner')
        end

        it 'changes owner successfully by email' do
          command.call('test-project', 'new@example.com')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Владелец проекта')
            expect(options[:text]).to include('new@example.com')
            expect(options[:text]).to include('viewer')
          end

          project.reload
          expect(project.memberships.find_by(role_cd: 0).user).to eq(new_owner)
          expect(project.memberships.find_by(role_cd: 1).user).to eq(old_owner)
        end

        it 'changes owner successfully by telegram username' do
          # Create telegram user with correct association
          telegram_user = create(:telegram_user, username: 'newowner')
          new_owner.update!(telegram_user: telegram_user)

          # Create a real command instance for this test to access the database
          real_controller = Telegram::WebhookController.new
          real_command = described_class.new(real_controller)

          # Mock respond_with for the real controller
          allow(real_controller).to receive(:respond_with)
          allow(real_controller).to receive(:developer?).and_return(true)

          real_command.call('test-project', '@newowner')

          expect(real_controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('new@example.com')
          end

          project.reload
          expect(project.memberships.find_by(role_cd: 0).user).to eq(new_owner)
        end

        it 'handles non-existent project' do
          command.call('non-existent', 'new@example.com')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('не найден')
          end
        end

        it 'handles non-existent user' do
          command.call('test-project', 'nonexistent@example.com')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('не найден в системе')
          end
        end

        it 'handles when user is already owner' do
          command.call('test-project', 'old@example.com')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('уже является владельцем')
          end
        end
      end

      context 'with more than 2 arguments' do
        it 'shows usage help' do
          command.call('arg1', 'arg2', 'arg3')

          expect(controller).to have_received(:respond_with) do |_type, options|
            expect(options[:text]).to include('Команда /owner')
            expect(options[:text]).to include('управление владельцами проектов')
          end
        end
      end
    end
  end

  describe 'private methods' do
    let(:real_controller) { Telegram::WebhookController.new }
    let(:real_command) { described_class.new(real_controller) }
    let(:user) { create(:user, :with_telegram, name: 'Test User', email: 'test@example.com') }

    before do
      user.telegram_user.update!(username: 'testuser')
    end

    describe '#find_user_by_identifier' do
      it 'finds user by email' do
        found_user = real_command.send(:find_user_by_identifier, 'test@example.com')
        expect(found_user).to eq(user)
      end

      it 'finds user by telegram username with @' do
        found_user = real_command.send(:find_user_by_identifier, '@testuser')
        expect(found_user).to eq(user)
      end

      it 'finds user by telegram username without @' do
        found_user = real_command.send(:find_user_by_identifier, 'testuser')
        expect(found_user).to eq(user)
      end

      it 'finds user by ID' do
        found_user = real_command.send(:find_user_by_identifier, user.id.to_s)
        expect(found_user).to eq(user)
      end

      it 'finds user by name' do
        found_user = real_command.send(:find_user_by_identifier, 'Test User')
        expect(found_user).to eq(user)
      end

      it 'returns nil for non-existent user' do
        found_user = real_command.send(:find_user_by_identifier, 'nonexistent')
        expect(found_user).to be_nil
      end
    end

    describe '#format_user_info_compact' do
      it 'formats user with all info' do
        formatted = real_command.send(:format_user_info_compact, user)
        expect(formatted).to include('Test User')
        expect(formatted).to include('test@example.com')
        expect(formatted).to include('@testuser')
      end

      it 'formats user without telegram username' do
        allow(user).to receive(:telegram_user).and_return(nil)
        formatted = real_command.send(:format_user_info_compact, user)
        expect(formatted).to include('Test User')
        expect(formatted).to include('test@example.com')
        expect(formatted).not_to include('@testuser')
      end

      it 'formats user with only ID' do
        user.update!(name: nil, email: nil)
        allow(user).to receive(:telegram_user).and_return(nil)
        formatted = real_command.send(:format_user_info_compact, user)
        expect(formatted).to include("ID: #{user.id}")
      end
    end

    describe '#truncate_string' do
      it 'returns original string if shorter than max' do
        result = real_command.send(:truncate_string, 'short', 10)
        expect(result).to eq('short')
      end

      it 'truncates string if longer than max' do
        result = real_command.send(:truncate_string, 'this is a very long string', 10)
        expect(result).to eq('this is...')
      end
    end
  end
end
