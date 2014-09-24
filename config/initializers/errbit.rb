if Rails.env.production? && defined? Airbrake
  Airbrake.configure do |config|
    config.api_key = '9fae50e238e0185b06e2c33932b79423'
    config.host    = 'errbit.brandymint.ru'
    config.port    = 80
    config.secure  = config.port == 443
  end
end
