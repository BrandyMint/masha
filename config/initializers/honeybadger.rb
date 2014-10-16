Honeybadger.configure do |config|
  #config.development_environments = ['test', 'cucumber']
  config.api_key = 'a682a615'
  config.debug   = Rails.env.development?

  #config.ignore_by_filter do |exception_data|
    #exception_data[:error_class].is_a? TastyError
  #end

  # Как только ее ставим, получаем
  # stack overflow в dev и test режимах
  # config.send_local_variables = true

  #config.ignore << 'Test error'
  #config.ignore << TastyError
  #config.ignore << HumanizedError
  #config.ignore << Authority::SecurityViolation
  #config.ignore << ActiveRecord::RecordInvalid
  #config.ignore << ActiveRecord::RecordNotFound
  #config.ignore << Grape::Exceptions::ValidationErrors
  #config.ignore << UserAuthenticator::InvalidPassword
  #config.ignore << UserCreator::UrlExists
  #config.ignore << 'Grape::PredefinedError'
  #config.ignore << 'Grape::PredefinedError: No X-User-Token'
  #config.ignore << EntryJanitor::LiveFeedLimit
  #config.ignore << ActionController::InvalidCrossOriginRequest
  #config.ignore << ActionController::UnknownHttpMethod
  #config.ignore << EntryJanitor::LiveFeedHonoredUser

  config.user_information = "Error ID: {{error_id}}"
  #config.async do |notice|
  #WorkingBadger.perform_async(notice.to_json)
  #end
end

