# frozen_string_literal: true

# Send startup notification to developer in production
Rails.application.config.after_initialize do
  NotifiedVersion.create version: AppVersion.to_s if Rails.env.production?
end
