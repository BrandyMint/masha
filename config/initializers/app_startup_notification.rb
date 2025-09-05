# frozen_string_literal: true

# Send startup notification to developer in production
Rails.application.config.after_initialize do
  if Rails.env.production?
    begin
      # Schedule the startup notification job
      AppStartupNotificationJob.perform_later(AppVersion.to_s)
      Rails.logger.info("Scheduled startup notification for version #{AppVersion}")
    rescue StandardError => e
      Rails.logger.error("Failed to schedule startup notification: #{e.message}")
      # Don't let startup notification failure prevent app startup
    end
  end
end
