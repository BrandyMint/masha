# frozen_string_literal: true

class TelegramUser < ApplicationRecord
  has_one :user, dependent: :restrict_with_exception

  validates :id, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def self.find_or_create_by_telegram_data!(data)
    create_with(
      data.slice('first_name', 'last_name', 'username', 'photo_url')
    )
      .find_or_create_by!(id: data.fetch('id'))
  end

  # chat =>
  # {"id"=>943084337, "first_name"=>"Danil", "last_name"=>"Pismenny", "username"=>"pismenny", "type"=>"private"}
  def update_from_chat!(chat)
    assign_attributes chat.slice(*%w[first_name last_name username])
    save! if changed?
  end

  def name
    [first_name, last_name].join(' ').presence || "Incognito(#{id})"
  end

  def public_name
    telegram_nick
  end

  def telegram_nick
    "@#{username}"
  end
end
