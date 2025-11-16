# frozen_string_literal: true

class StartCommand < BaseCommand
  command_metadata(hidden: true)

  def call(word = nil, *_other_words)
    if word.to_s.start_with? TelegramHelper::AUTH_PREFIX
      handle_auth_start(word)
    else
      respond_with :message, text: multiline('С возращением!', nil, nil, HelpCommand.new(controller).help_message)
    end
  end

  private

  def handle_auth_start(word)
    session_token = word.delete_prefix TelegramHelper::AUTH_PREFIX
    verifier = Rails.application.message_verifier :telegram
    data = { st: session_token, tid: telegram_user.id, t: Time.zone.now.to_i }
    token = verifier.generate(data, purpose: :login)
    respond_with :message,
                 text: "Вы авторизованы! Перейдите на сайт: #{Rails.application.routes.url_helpers.telegram_confirm_url(token:)}"
  end
end
