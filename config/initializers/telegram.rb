# Enable typecasting:
# Has bugs with rspec and async mode
# Telegram::Bot::Client.typed_response!

Rails.application.config.telegram_updates_controller.logger =
  ActiveSupport::Logger.new( Rails.root.join 'log', 'telegram.log').
  tap { |logger| logger.formatter = AutoLogger::Formatter.new }

Rails.application.config.telegram_updates_controller.session_store = :redis_store, {expires_in: 1.month}
