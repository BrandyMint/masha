require 'telegram/bot'
$telegram = Telegram::Bot::Api.new ENV['TELEGRAM_TOKEN'] || Rails.credentials.telegram_api_key
