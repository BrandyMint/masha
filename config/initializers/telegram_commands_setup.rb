# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Пропускаем в тестовой среде и при отсутствии SECRET_KEY_BASE
  next if Rails.env.test? || ENV.key?('SECRET_KEY_BASE_DUMMY')

  Rails.logger.info "[TelegramCommandsSetup] Initializing automatic commands setup"

  # Запускаем job для установки команд
  begin
    case Rails.env
    when 'production'
      # В production запускаем всегда для надежности
      TelegramCommandsSetupJob.launch_safely
      Rails.logger.info "[TelegramCommandsSetup] Commands setup job launched for production"
    when 'development'
      # В development запускаем только если явно указано
      if ENV['AUTO_SETUP_TELEGRAM_COMMANDS'] == 'true'
        TelegramCommandsSetupJob.launch_safely
        Rails.logger.info "[TelegramCommandsSetup] Commands setup job launched for development"
      else
        Rails.logger.info "[TelegramCommandsSetup] Skipping commands setup in development (set AUTO_SETUP_TELEGRAM_COMMANDS=true to enable)"
      end
    when 'staging'
      # В staging запускаем как в production
      TelegramCommandsSetupJob.launch_safely
      Rails.logger.info "[TelegramCommandsSetup] Commands setup job launched for staging"
    end

  rescue StandardError => e
    Rails.logger.error "[TelegramCommandsSetup] Failed to launch commands setup job: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
  end
end