# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'telegram:bot:set_commands' do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    allow(Telegram.bots[:default]).to receive(:set_my_commands)
  end

  after do
    Rake::Task['telegram:bot:set_commands'].reenable
  end

  it 'sets commands via Telegram API' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands).with(
      commands: array_including(
        hash_including(command: 'add', description: String),
        hash_including(command: 'start', description: String),
        hash_including(command: 'help', description: String)
      )
    )
  end

  it 'excludes developer_only commands' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands) do |args|
      command_names = args[:commands].map { |c| c[:command] }
      expect(command_names).not_to include('notify', 'merge')
    end
  end

  it 'includes all public commands' do
    Rake::Task['telegram:bot:set_commands'].invoke

    expect(Telegram.bots[:default]).to have_received(:set_my_commands) do |args|
      expect(args[:commands].size).to be >= 11
    end
  end
end
