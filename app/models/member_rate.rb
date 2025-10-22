# frozen_string_literal: true

class MemberRate < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, inclusion: { in: %w[RUB EUR USD] }
  validates :project_id, uniqueness: { scope: :user_id }

  CURRENCIES = %w[RUB EUR USD].freeze

  def rate_with_currency
    return nil if hourly_rate.blank?

    "#{hourly_rate} #{currency}"
  end
end
