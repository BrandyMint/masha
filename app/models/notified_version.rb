# frozen_string_literal: true

# Отслеживание версий приложения для уведомлений пользователей при обновлениях.
class NotifiedVersion < ApplicationRecord
  validates :version, presence: true, uniqueness: true

  after_commit on: :create do
    AppStartupNotificationJob.perform_later version
  end
end
