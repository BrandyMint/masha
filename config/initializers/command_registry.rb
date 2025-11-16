Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    Telegram::WebhookController,
    %w[report rate projects attach start help users add edit clients notify test reset merge]
  )
end
