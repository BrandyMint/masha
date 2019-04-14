# Enable typecasting:
Telegram::Bot::Client.typed_response!

Rails.application.config.telegram_updates_controller.logger =
  ActiveSupport::Logger.new( Rails.root.join 'log', 'telegram.log').
  tap { |logger| logger.formatter = AutoLogger::Formatter.new }
