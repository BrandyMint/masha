# frozen_string_literal: true

# Пользователь Telegram с данными из API. Связан с User. Обрабатывает приглашения при
# создании или изменении username.
class TelegramUser < ApplicationRecord
  has_one :user, dependent: :restrict_with_exception

  validates :id, presence: true, numericality: { only_integer: true, greater_than: 0 }

  after_commit :check_and_process_invitations, on: :create

  def self.find_or_create_by_telegram_data!(data)
    create_with(
      data.slice('first_name', 'last_name', 'username', 'photo_url')
    )
      .find_or_create_by!(id: data.fetch('id'))
  end

  # chat =>
  # {"id"=>943084337, "first_name"=>"Danil", "last_name"=>"Pismenny", "username"=>"pismenny", "type"=>"private"}
  def update_from_chat!(chat)
    old_username = username
    assign_attributes chat.slice(*%w[first_name last_name username])
    return unless changed?

    save!
    # Check invitations if username changed
    check_and_process_invitations if username != old_username
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

  def developer?
    id == ApplicationConfig.developer_telegram_id
  end

  private

  def check_and_process_invitations
    return if username.blank?

    invitations = Invite.activate_for_telegram_user(self)
    return if invitations.blank?

    # Send notifications for activated invitations
    invitations.each do |invite|
      send_invitation_notification(invite)
    end

    invitations.destroy_all
  end

  def send_invitation_notification(invite)
    TelegramNotificationJob.perform_later(
      user_id: id,
      message: "🎉 Вы были добавлены в проект '#{invite.project.name}' с ролью '#{invite.role}' пользователем #{invite.user}!"
    )
  end
end
