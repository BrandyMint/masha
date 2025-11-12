Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    Telegram::WebhookController,
    %w[day summary report projects attach start help version users add adduser hours edit rename client notify reset]
  )
end
