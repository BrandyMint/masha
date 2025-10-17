# frozen_string_literal: true

# Background job для автоматической установки команд Telegram бота
# Запускается при старте приложения и обеспечивает синхронизацию команд
class TelegramCommandsSetupJob < ApplicationJob
  # Таймаут выполнения задачи
  retry_on StandardError, wait: 30.seconds, attempts: 3

  queue_as :default

  # Выполняет установку команд Telegram
  def perform(force: false)
    Rails.logger.info "[TelegramCommandsSetup] Starting commands setup job"

    begin
      # Проверяем, нужно ли обновлять команды
      manager = Telegram::CommandsManager.new

      unless force || manager.commands_outdated?
        Rails.logger.info "[TelegramCommandsSetup] Commands are up to date, skipping"
        return
      end

      Rails.logger.info "[TelegramCommandsSetup] Commands outdated, setting up..."

      # Устанавливаем команды
      result = manager.set_commands!

      if result[:success]
        Rails.logger.info "[TelegramCommandsSetup] ✅ Commands successfully set: #{result[:commands_count]} commands"

        # Логируем установленные команды для отладки
        commands_list = result[:commands].map { |cmd| "/#{cmd[:command]}" }.join(', ')
        Rails.logger.debug "[TelegramCommandsSetup] Commands: #{commands_list}"
      else
        Rails.logger.error "[TelegramCommandsSetup] ❌ Failed to set commands: #{result[:message]}"
        Rails.logger.error "[TelegramCommandsSetup] Errors: #{result[:errors].join(', ')}" if result[:errors].any?
      end

    rescue Telegram::Bot::Error => e
      Rails.logger.error "[TelegramCommandsSetup] Telegram API error: #{e.message}"
      Bugsnag.notify(e) { |b| b.metadata = { job: 'TelegramCommandsSetupJob', error_type: 'telegram_api' } }
      raise
    rescue StandardError => e
      Rails.logger.error "[TelegramCommandsSetup] Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Bugsnag.notify(e) { |b| b.metadata = { job: 'TelegramCommandsSetupJob', error_type: 'unexpected' } }
      raise
    end
  end

  # Класс метод для запуска с проверкой на дублирование
  def self.launch_safely(force: false)
    Rails.logger.info "[TelegramCommandsSetup] Attempting to launch setup job"

    # Проверяем, не запущена ли уже задача
    if ActiveJob::Base.queue_adapter.enqueued_jobs.any? { |job| job[:job] == self }
      Rails.logger.info "[TelegramCommandsSetup] Job already enued, skipping"
      return false
    end

    # Запускаем задачу с задержкой, чтобы дать приложению полностью загрузиться
    perform_later(wait: 5.seconds, force: force)
    Rails.logger.info "[TelegramCommandsSetup] Job ened with 5 second delay"
    true
  end

  # Принудительное обновление команд
  def self.force_update
    Rails.logger.info "[TelegramCommandsSetup] Force updating commands"
    perform_later(force: true)
  end
end