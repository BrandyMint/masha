# frozen_string_literal: true

module Telegram
  module Commands
    class SetCommandsCommand < BaseCommand
      def call(*_args)
        unless developer_user?
          respond_with :message, text: I18n.t('telegram_bot.access_denied')
          return
        end

        respond_with :message, text: '🔧 Устанавливаю команды бота...'

        manager = Telegram::CommandsManager.new(bot: controller.bot)
        result = manager.set_commands!

        if result[:success]
          respond_with :message,
                       text: "#{result[:message]}\n\n📊 Установлено команд: #{result[:commands_count]}"
        else
          respond_with :message, text: result[:message]
        end
      rescue StandardError => e
        Bugsnag.notify(e) { |b| b.metadata = { user_id: current_user&.id, action: 'set_commands_command' } }
        Rails.logger.error "Set commands error: #{e.message}"
        respond_with :message, text: I18n.t('telegram_bot.error')
      end

      private

      def developer_user?
        return false unless current_user

        current_user.telegram_user&.telegram_id.in?(ENV['DEVELOPER_TELEGRAM_IDS'].to_s.split(',').map(&:to_i))
      end
    end
  end
end
