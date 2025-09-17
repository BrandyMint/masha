# frozen_string_literal: true

unless ENV.key? 'SECRET_KEY_BASE_DUMMY'
  # Send startup notification to developer in production
  Rails.application.config.after_initialize do
    NotifiedVersion.create version: AppVersion.to_s if Rails.env.production? && NotifiedVersion.table_exists?
  end
end
