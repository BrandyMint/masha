# frozen_string_literal: true

class MergeCommand < BaseCommand
  command_metadata(developer_only: true)

  def call(email = nil, telegram_username = nil, *)
    if email.blank? || telegram_username.blank?
      respond_with :message, text: 'Использование: /merge email@example.com telegram_username'
      return
    end

    TelegramUserMerger.new(email, telegram_username, controller: controller).merge
  end
end
