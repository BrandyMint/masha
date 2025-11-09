Rails.application.config.after_initialize do
  Telegram::CommandRegistry.register(
    %w[day summary report projects attach start help version
       users merge add new adduser hours edit rename
       rate client reset]
  )
end
