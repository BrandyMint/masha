# frozen_string_literal: true

class SetCommandsCommand < BaseCommand
  command_metadata(developer_only: true)

  def call
    commands = Telegram::CommandRegistry.public_commands
                                        .map do |cmd|
      command_name = Telegram::CommandRegistry.command_name(cmd)
      description_key = "telegram.commands.descriptions.#{command_name}"

      {
        command: command_name,
        description: I18n.t(description_key, default: command_name.humanize)
      }
    end

    Telegram.bots[:default].set_my_commands(commands: commands)

    message = "✅ Команды установлены успешно! (#{commands.size} команд)\n\n"
    message += "📋 Установленные команды:\n"
    commands.each do |cmd|
      message += "  /#{cmd[:command]} - #{cmd[:description]}\n"
    end

    respond_with :message, text: message
  rescue StandardError => e
    respond_with :message, text: "❌ Ошибка установки команд: #{e.message}"
  end
end
