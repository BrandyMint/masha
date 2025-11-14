# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::CommandRegistry do
  describe '.all_command_classes' do
    it 'returns all command classes' do
      commands = described_class.all_command_classes

      expect(commands).to include(AddCommand, StartCommand, NotifyCommand, HelpCommand)
      expect(commands.all? { |c| c < BaseCommand }).to be true
    end

    it 'returns at least 14 commands' do
      expect(described_class.all_command_classes.size).to be >= 14
    end
  end

  describe '.public_commands' do
    it 'excludes developer_only commands' do
      commands = described_class.public_commands

      expect(commands).to include(AddCommand, StartCommand, HelpCommand)
      expect(commands).not_to include(NotifyCommand) # developer_only
    end
  end

  describe '.developer_commands' do
    it 'includes only developer_only commands' do
      commands = described_class.developer_commands

      expect(commands).to include(NotifyCommand, MergeCommand)
      expect(commands).not_to include(AddCommand, StartCommand)
    end
  end

  describe '.command_name' do
    it 'extracts command name from class' do
      expect(described_class.command_name(AddCommand)).to eq('add')
      expect(described_class.command_name(StartCommand)).to eq('start')
      expect(described_class.command_name(NotifyCommand)).to eq('notify')
    end
  end
end
