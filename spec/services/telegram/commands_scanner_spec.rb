# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::CommandsScanner do
  let(:scanner) { described_class.new }

  describe '#scan_commands' do
    context 'when exclude_developer: true' do
      it 'returns only user commands' do
        commands = scanner.scan_commands(exclude_developer: true)

        expect(commands).to be_an(Array)
        expect(commands.count).to be > 0

        # Check that user commands are present
        command_names = commands.map { |cmd| cmd[:command] }
        expect(command_names).to include('start', 'help', 'projects', 'summary')

        # Check that developer commands are excluded
        expect(command_names).not_to include('users', 'merge')
      end
    end

    context 'when exclude_developer: false' do
      it 'returns all commands including developer commands' do
        commands = scanner.scan_commands(exclude_developer: false)

        expect(commands).to be_an(Array)
        expect(commands.count).to be > 0

        # Check that both user and developer commands are present
        command_names = commands.map { |cmd| cmd[:command] }
        expect(command_names).to include('start', 'help', 'projects', 'summary')
        expect(command_names).to include('users', 'merge')
      end
    end
  end

  describe '#all_commands' do
    it 'returns all commands including developer commands' do
      commands = scanner.all_commands

      expect(commands).to be_an(Array)
      expect(commands.count).to be > 0

      # Check structure of command objects
      command = commands.first
      expect(command).to have_key(:command)
      expect(command).to have_key(:description)
      expect(command).to have_key(:source)
      expect(command).to have_key(:developer_only)

      # Check that both user and developer commands are present
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to include('start', 'help', 'users', 'merge')
    end
  end

  describe '#user_commands' do
    it 'returns only user commands' do
      commands = scanner.user_commands

      expect(commands).to be_an(Array)
      expect(commands.count).to be > 0

      # Check that developer commands are excluded
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to include('start', 'help', 'projects')
      expect(command_names).not_to include('users', 'merge')

      # Check that no command is marked as developer_only
      developer_commands = commands.select { |cmd| cmd[:developer_only] }
      expect(developer_commands).to be_empty
    end
  end

  describe '#developer_commands' do
    it 'returns only developer commands' do
      commands = scanner.developer_commands

      expect(commands).to be_an(Array)

      # Check that only developer commands are returned
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to include('users', 'merge')

      # Check that all commands are marked as developer_only
      non_developer_commands = commands.reject { |cmd| cmd[:developer_only] }
      expect(non_developer_commands).to be_empty
    end
  end

  describe '#filter_developer_commands' do
    it 'removes developer commands from array' do
      all_commands = [
        { command: 'start', developer_only: false },
        { command: 'help', developer_only: false },
        { command: 'users', developer_only: true },
        { command: 'merge', developer_only: true }
      ]

      filtered = scanner.filter_developer_commands(all_commands)

      expect(filtered.count).to eq(2)
      expect(filtered.map { |cmd| cmd[:command] }).to contain_exactly('start', 'help')
    end
  end

  describe '#command_method?' do
    it 'returns true for command methods' do
      expect(scanner.send(:command_method?, 'start!')).to be true
      expect(scanner.send(:command_method?, 'help!')).to be true
      expect(scanner.send(:command_method?, 'test_command!')).to be true
    end

    it 'returns false for non-command methods' do
      expect(scanner.send(:command_method?, 'start')).to be false
      expect(scanner.send(:command_method?, '_private_method!')).to be false
      expect(scanner.send(:command_method?, 'regular_method')).to be false
    end
  end

  describe '#developer_command?' do
    it 'returns true for developer commands' do
      expect(scanner.send(:developer_command?, 'users')).to be true
      expect(scanner.send(:developer_command?, 'merge')).to be true
    end

    it 'returns false for regular commands' do
      expect(scanner.send(:developer_command?, 'start')).to be false
      expect(scanner.send(:developer_command?, 'help')).to be false
      expect(scanner.send(:developer_command?, 'projects')).to be false
    end
  end

  describe '#get_command_description' do
    before do
      # Ensure locale is set
      I18n.locale = :ru
    end

    it 'returns description from localization' do
      description = scanner.send(:get_command_description, 'start')
      expect(description).to eq('Начать работу с ботом')
    end

    it 'returns humanized name for unknown command' do
      description = scanner.send(:get_command_description, 'unknown_command')
      expect(description).to eq('Unknown command')
    end
  end

  describe '#format_commands' do
    before do
      # Setup some mock commands
      scanner.instance_variable_set(:@commands, {
                                      'start' => {
                                        command: 'start',
                                        description: 'Начать работу с ботом',
                                        source: 'Telegram::WebhookController',
                                        developer_only: false
                                      },
                                      'users' => {
                                        command: 'users',
                                        description: 'Управление пользователями (разработчикам)',
                                        source: 'Telegram::Commands::UsersCommand',
                                        developer_only: true
                                      }
                                    })
    end

    it 'formats commands correctly' do
      commands = scanner.send(:format_commands)

      expect(commands.count).to eq(2)
      expect(commands.first).to have_key(:command)
      expect(commands.first).to have_key(:description)
      expect(commands.first).to have_key(:source)
      expect(commands.first).to have_key(:developer_only)
    end

    it 'sorts commands by name' do
      commands = scanner.send(:format_commands)
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to eq(%w[start users])
    end
  end
end
