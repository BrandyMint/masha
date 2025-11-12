Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    %w[day summary report projects attach start help version users add new adduser hours edit rename client notify reset]
  )
end
