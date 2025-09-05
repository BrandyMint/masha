# frozen_string_literal: true

class AppStartupNotificationJob < UniqueJob
  queue_as :default

  def perform(version)
    return unless Rails.env.production?

    developer_telegram_id = ApplicationConfig.developer_telegram_id
    return unless developer_telegram_id

    message = format_startup_message(version)

    TelegramNotificationJob.perform_later(
      user_id: developer_telegram_id,
      message: message
    )

    Rails.logger.info("Sent startup notification for version #{version} to developer #{developer_telegram_id}")
  end

  private

  def format_startup_message(version)
    timestamp = Time.current.strftime('%d.%m.%Y %H:%M:%S %Z')

    "🚀 Запущена новая версия Masha v#{version}\n" \
    "⏰ Время запуска: #{timestamp}"
  end
end
