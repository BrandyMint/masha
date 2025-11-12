Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    Telegram::WebhookController,
    %w[day summary report rate projects attach start help version users add hours edit client notify reset]
  )
end
