# frozen_string_literal: true

class NotifiedVersion < ApplicationRecord
  validates :version, presence: true, uniqueness: true

  after_commit on: :create do
    AppStartupNotificationJob.perform_later version
  end
end
