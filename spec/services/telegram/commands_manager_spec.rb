# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::CommandsManager do
  let(:manager) { described_class.new }
  let(:mock_bot) { double('Telegram::Bot') }
  let(:successful_response) { { 'ok' => true, 'result' => [] } }
  let(:error_response) { { 'ok' => false, 'description' => 'Test error' } }

  before do
    allow(Telegram).to receive(:bot).and_return(mock_bot)
    I18n.locale = :ru
  end

  describe '#initialize' do
    it 'initializes with default bot' do
      expect(manager.bot).to eq(mock_bot)
      expect(manager.scanner).to be_a(Telegram::CommandsScanner)
      expect(manager.errors).to be_a(ActiveModel::Errors)
    end

    it 'accepts custom bot' do
      custom_bot = double('CustomBot')
      custom_manager = described_class.new(bot: custom_bot)
      expect(custom_manager.bot).to eq(custom_bot)
    end
  end

  describe '#set_commands!' do
    context 'with valid commands' do
      before do
        allow(manager).to receive(:prepare_commands).and_return([
                                                                  { command: 'start', description: 'Начать работу с ботом' },
                                                                  { command: 'help', description: 'Показать справку' }
                                                                ])
        allow(mock_bot).to receive(:set_my_commands).and_return(successful_response)
      end

      it 'successfully sets commands' do
        result = manager.set_commands!

        expect(result[:success]).to be true
        expect(result[:message]).to include('Команды бота успешно установлены')
        expect(result[:commands_count]).to eq(2)
        expect(mock_bot).to have_received(:set_my_commands).with(
          commands: array_including(
            hash_including(command: 'start', description: 'Начать работу с ботом'),
            hash_including(command: 'help', description: 'Показать справку')
          )
        )
      end

      it 'logs success message' do
        expect(Rails.logger).to receive(:info).with(/Telegram bot commands successfully set/)
        manager.set_commands!
      end
    end

    context 'with no commands found' do
      before do
        allow(manager).to receive(:prepare_commands).and_return([])
      end

      it 'returns failure result' do
        result = manager.set_commands!

        expect(result[:success]).to be false
        expect(result[:message]).to include('Команды не найдены')
        expect(result[:commands_count]).to eq(0)
      end

      it 'adds validation error' do
        manager.set_commands!
        expect(manager.errors[:no_commands]).to include('Команды не найдены')
      end
    end

    context 'with API error' do
      before do
        allow(manager).to receive(:prepare_commands).and_return([
                                                                  { command: 'start', description: 'Начать работу с ботом' }
                                                                ])
        allow(mock_bot).to receive(:set_my_commands).and_return(error_response)
      end

      it 'handles API error' do
        result = manager.set_commands!

        expect(result[:success]).to be false
        expect(result[:message]).to include('Ошибка при установке команд: Test error')
        expect(result[:errors]).to include('Test error')
      end

      it 'adds API error' do
        manager.set_commands!
        expect(manager.errors[:api_error]).to include('Test error')
      end
    end

    context 'with exception' do
      before do
        allow(mock_bot).to receive(:set_my_commands).and_raise(StandardError, 'Unexpected error')
      end

      it 'handles exceptions' do
        expect(Bugsnag).to receive(:notify)
        result = manager.set_commands!

        expect(result[:success]).to be false
        expect(result[:message]).to include('Ошибка при установке команд: Unexpected error')
      end
    end
  end

  describe '#all_commands' do
    it 'returns user commands from scanner' do
      commands = manager.all_commands
      expect(commands).to be_an(Array)
      expect(commands.count).to be > 0

      # Should not include developer commands
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to include('start', 'help', 'projects')
      expect(command_names).not_to include('users', 'merge')
    end
  end

  describe '#commands_with_developer' do
    it 'returns all commands from scanner' do
      commands = manager.commands_with_developer
      expect(commands).to be_an(Array)
      expect(commands.count).to be > 0

      # Should include both user and developer commands
      command_names = commands.map { |cmd| cmd[:command] }
      expect(command_names).to include('start', 'help', 'users', 'merge')
    end
  end

  describe '#current_commands' do
    context 'when API call succeeds' do
      before do
        allow(mock_bot).to receive(:get_my_commands).and_return(
          'ok' => true,
          'result' => [
            { 'command' => 'start', 'description' => 'Test start' },
            { 'command' => 'help', 'description' => 'Test help' }
          ]
        )
      end

      it 'returns current commands from API' do
        commands = manager.current_commands
        expect(commands.count).to eq(2)
        expect(commands.first['command']).to eq('start')
      end
    end

    context 'when API call fails' do
      before do
        allow(mock_bot).to receive(:get_my_commands).and_raise(StandardError, 'API error')
        allow(Rails.logger).to receive(:error)
      end

      it 'returns empty array and logs error' do
        commands = manager.current_commands
        expect(commands).to eq([])
        expect(Rails.logger).to have_received(:error).with(/Error getting current commands/)
      end
    end
  end

  describe '#commands_outdated?' do
    before do
      allow(manager).to receive(:all_commands).and_return([
                                                            { command: 'start', description: 'Local start description' },
                                                            { command: 'help', description: 'Local help description' }
                                                          ])
    end

    context 'when commands are the same' do
      before do
        allow(manager).to receive(:current_commands).and_return([
                                                                  { 'command' => 'start', 'description' => 'Local start description' },
                                                                  { 'command' => 'help', 'description' => 'Local help description' }
                                                                ])
      end

      it 'returns false' do
        expect(manager.commands_outdated?).to be false
      end
    end

    context 'when commands differ' do
      before do
        allow(manager).to receive(:current_commands).and_return([
                                                                  { 'command' => 'start', 'description' => 'Different description' },
                                                                  { 'command' => 'help', 'description' => 'Local help description' }
                                                                ])
      end

      it 'returns true' do
        expect(manager.commands_outdated?).to be true
      end
    end

    context 'when command counts differ' do
      before do
        allow(manager).to receive(:current_commands).and_return([
                                                                  { 'command' => 'start', 'description' => 'Local start description' }
                                                                ])
      end

      it 'returns true' do
        expect(manager.commands_outdated?).to be true
      end
    end
  end

  describe '#sync_commands_if_needed' do
    context 'when commands are outdated' do
      before do
        allow(manager).to receive(:commands_outdated?).and_return(true)
        allow(manager).to receive(:set_commands!).and_return(
          { success: true, message: 'Commands updated' }
        )
      end

      it 'sets commands and returns success' do
        result = manager.sync_commands_if_needed
        expect(result[:success]).to be true
        expect(result[:message]).to include('Commands updated')
        expect(manager).to have_received(:set_commands!)
      end
    end

    context 'when commands are up to date' do
      before do
        allow(manager).to receive(:commands_outdated?).and_return(false)
      end

      it 'returns success without setting commands' do
        result = manager.sync_commands_if_needed
        expect(result[:success]).to be true
        expect(result[:message]).to include('Команды актуальны')
        expect(manager).not_to have_received(:set_commands!)
      end
    end
  end

  describe '#format_commands_for_display' do
    before do
      allow(manager).to receive(:all_commands).and_return([
                                                            { command: 'start', description: 'Начать работу с ботом',
                                                              developer_only: false },
                                                            { command: 'users', description: 'Управление пользователями',
                                                              developer_only: true }
                                                          ])
    end

    it 'formats commands correctly' do
      formatted = manager.format_commands_for_display

      expect(formatted).to include('Список команд бота:')
      expect(formatted).to include('📱 /start - Начать работу с ботом')
      expect(formatted).to include('🔐 /users - Управление пользователями')
      expect(formatted).to include('Всего команд: 2')
    end

    context 'with no commands' do
      before do
        allow(manager).to receive(:all_commands).and_return([])
      end

      it 'returns no commands message' do
        formatted = manager.format_commands_for_display
        expect(formatted).to include('Команды не найдены')
      end
    end
  end

  describe '#validate_commands' do
    context 'with valid commands' do
      let(:valid_commands) do
        [
          { command: 'start', description: 'Valid description' },
          { command: 'help_command', description: 'Another valid description' }
        ]
      end

      it 'returns empty errors array' do
        errors = manager.validate_commands(valid_commands)
        expect(errors).to be_empty
      end
    end

    context 'with invalid command format' do
      let(:invalid_commands) do
        [
          { command: 'Invalid-Command', description: 'Description' },
          { command: 'valid_command', description: 'Description' }
        ]
      end

      it 'returns format error' do
        errors = manager.validate_commands(invalid_commands)
        expect(errors).to include('Invalid command format: Invalid-Command')
      end
    end

    context 'with command name too long' do
      let(:long_command_name) { 'a' * 33 }
      let(:invalid_commands) do
        [
          { command: long_command_name, description: 'Description' }
        ]
      end

      it 'returns length error' do
        errors = manager.validate_commands(invalid_commands)
        expect(errors).to include("Command name too long: #{long_command_name}")
      end
    end

    context 'with description too long' do
      let(:long_description) { 'a' * 257 }
      let(:invalid_commands) do
        [
          { command: 'start', description: long_description }
        ]
      end

      it 'returns description length error' do
        errors = manager.validate_commands(invalid_commands)
        expect(errors).to include('Description too long for command: start')
      end
    end

    context 'with too many commands' do
      let(:too_many_commands) do
        (1..101).map { |i| { command: "cmd#{i}", description: "Description #{i}" } }
      end

      it 'returns count error' do
        errors = manager.validate_commands(too_many_commands)
        expect(errors).to include('Too many commands: 101 (max 100)')
      end
    end
  end

  describe '#prepare_commands' do
    context 'with valid commands' do
      before do
        allow(manager).to receive(:all_commands).and_return([
                                                              { command: 'start', description: 'Valid description' }
                                                            ])
        allow(manager).to receive(:validate_commands).and_return([])
      end

      it 'returns commands' do
        commands = manager.send(:prepare_commands)
        expect(commands.count).to eq(1)
        expect(commands.first[:command]).to eq('start')
      end
    end

    context 'with validation errors' do
      before do
        allow(manager).to receive(:all_commands).and_return([
                                                              { command: 'invalid-command', description: 'Description' }
                                                            ])
        allow(manager).to receive(:validate_commands).and_return(['Invalid format'])
      end

      it 'returns empty array and adds error' do
        commands = manager.send(:prepare_commands)
        expect(commands).to be_empty
        expect(manager.errors[:validation]).to include('Invalid format')
      end
    end
  end
end
