# frozen_string_literal: true

class UsersCommand < BaseCommand
  def call(*)
    unless developer?
      respond_with :message, text: 'Эта команда доступна только разработчику системы'
      return
    end

    users_text = User.includes(:telegram_user, :projects)
                     .map { |user| format_user_info(user) }
                     .join("\n\n")

    respond_with :message, text: users_text.presence || 'Пользователи не найдены', parse_mode: :Markdown
  end
end
