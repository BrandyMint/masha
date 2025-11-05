class Client < ApplicationRecord
  belongs_to :user
  has_many :projects, dependent: :nullify

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
