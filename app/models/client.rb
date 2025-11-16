# frozen_string_literal: true
class Client < ApplicationRecord
  include Authority::Abilities

  belongs_to :user
  has_many :projects, dependent: :nullify

  scope :alphabetically, -> { order(key: :asc) }

  validates :key, presence: true,
                  uniqueness: { scope: :user_id },
                  format: { with: /\A[a-z0-9_-]+\z/ },
                  length: { minimum: 2, maximum: 50 }
  validates :name, presence: true, length: { maximum: 255 }

  def to_param
    key
  end

  delegate :count, to: :projects, prefix: true
end
