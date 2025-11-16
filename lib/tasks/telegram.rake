# frozen_string_literal: true

namespace :telegram do
  namespace :bot do
    desc 'Set bot commands menu for all users'
    task set_commands: :environment do
      commands = Telegram::CommandRegistry.
        public_commands.
        sort_by(&:to_s).
        map do |cmd|
        command_name = Telegram::CommandRegistry.command_name(cmd)
        description_key = "telegram.commands.descriptions.#{command_name}"

        {
          command: command_name,
          description: I18n.t(description_key, default: command_name.humanize)
        }
      end

      Telegram.bots[:default].set_my_commands(commands: commands)

      puts "✅ Commands set successfully! (#{commands.size} commands)"
      puts ''
      puts '📋 Installed commands:'
      commands.each do |cmd|
        puts "  /#{cmd[:command]} - #{cmd[:description]}"
      end
    end
  end
end
